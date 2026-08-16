"""Emit one TSV row per class/function/method: path, line, kind, vis, name, signature, doc.

Stdlib `ast` only, so it runs in a bare `python:3-slim` container with no install.
Signature and docstring are mechanical; the audit's agents supply purpose + verdict.
"""

import ast
import sys

COLS = ("path", "line", "kind", "vis", "name", "signature", "doc")


def cell(text, limit=200):
    flat = " ".join(str(text).split())
    return flat[:limit]


def _arg(arg, default=None):
    out = arg.arg
    if arg.annotation:
        out += ":" + ast.unparse(arg.annotation)
    if default is not None:
        out += "=" + ast.unparse(default)
    return out


def signature(fn, drop_first=False):
    a = fn.args
    pos = a.posonlyargs + a.args
    if drop_first and pos and pos[0].arg in ("self", "cls"):
        pos = pos[1:]  # the receiver is noise in a fingerprint
    defaults = [None] * (len(pos) - len(a.defaults)) + list(a.defaults)
    parts = [_arg(x, d) for x, d in zip(pos, defaults)]
    if a.vararg:
        parts.append("*" + _arg(a.vararg))
    elif a.kwonlyargs:
        parts.append("*")
    parts += [_arg(x, d) for x, d in zip(a.kwonlyargs, a.kw_defaults)]
    if a.kwarg:
        parts.append("**" + _arg(a.kwarg))
    ret = "->" + ast.unparse(fn.returns) if fn.returns else ""
    return "(" + ", ".join(parts) + ")" + ret


def decorators(node):
    # Decorators are reachability evidence: a route/handler/fixture is called by a
    # framework, so a dead-code tool will wrongly call it unreachable.
    names = [ast.unparse(d).split("(")[0] for d in node.decorator_list]
    return "".join("@" + n + " " for n in names)


def rows(path, source):
    tree = ast.parse(source, filename=path)

    def walk(node, cls=None):
        for child in node.body:
            name = getattr(child, "name", None)
            if isinstance(child, ast.ClassDef):
                bases = ", ".join(ast.unparse(b) for b in child.bases)
                yield row(path, child, "class", name, f"{decorators(child)}({bases})")
                yield from walk(child, name)
            elif isinstance(child, (ast.FunctionDef, ast.AsyncFunctionDef)):
                kind = "method" if cls else "func"
                qual = f"{cls}.{name}" if cls else name
                sig = decorators(child) + signature(child, drop_first=bool(cls))
                yield row(path, child, kind, qual, sig)
                yield from walk(child, cls)  # closures still carry drift

    yield from walk(tree)


def row(path, node, kind, name, sig):
    vis = "priv" if node.name.startswith("_") else "pub"
    doc = ast.get_docstring(node) or ""
    return (path, node.lineno, kind, vis, name, sig, doc.split("\n\n")[0] if doc else "-")


SAMPLE = '''
class Wallet:
    """Holds cash."""
    @property
    def _fee(self, rate: float = 0.1, *args, strict: bool = True, **kw) -> float:
        return rate

def place(order) -> None:
    pass
'''


def selftest():
    got = ["\t".join(cell(c) for c in r) for r in rows("s.py", SAMPLE)]
    assert any("class\tpub\tWallet\t()\tHolds cash." in g for g in got), got
    assert any(
        "method\tpriv\tWallet._fee\t@property (rate:float=0.1, *args, strict:bool=True, **kw)->float\t-"
        in g
        for g in got
    ), got
    assert any("func\tpub\tplace\t(order)->None" in g for g in got), got
    print("extract_py selftest ok")


if __name__ == "__main__":
    args = sys.argv[1:]
    if args[:1] == ["--selftest"]:
        selftest()
        raise SystemExit(0)
    print("\t".join(COLS))
    for path in args:
        try:
            with open(path, encoding="utf-8") as fh:
                source = fh.read()
        except OSError as err:
            print(f"{path}\t0\tERROR\t-\t-\t-\t{cell(err)}")
            continue
        try:
            for r in rows(path, source):
                print("\t".join(cell(c) for c in r))
        except SyntaxError as err:
            print(f"{path}\t{err.lineno or 0}\tERROR\t-\t-\t-\t{cell(err.msg)}")

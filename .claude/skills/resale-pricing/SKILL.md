---
name: resale-pricing
description: >
  Price a product that you buy from a supplier and resell: compute break-even, margin
  and customer price with VAT and payment fee, build the price structure (base + per
  unit, cost steps), keep published unit prices exact, and show it all in tables.
  Use when the user asks "what should we charge", "are we too expensive", "what is our
  margin", "compare our prices with competitors", wants a pricing proposal or a margin
  table, or asks whether to show net or gross prices. Triggers on "pricing", "Preise",
  "margin", "Marge", "break-even", "VAT", "Umsatzsteuer", "netto/brutto", "price list".
---

# Resale pricing

Compute with a script, never by hand. Show tables, not prose.

## Inputs to get first

- Price list of the supplier. Read the footnotes: net or gross, VAT-free or not.
- Cost structure: base per order, price per unit, steps (weight class, volume tier).
- Payment fee in percent of the gross price. Mark it as an assumption until an invoice shows it.
- Competitor prices, as gross prices for the same quantities.
- Margin goal. Ask for the unit prices that the customer already sees (front page, price list).
- Customers: consumers or businesses.

## Formulas

```text
K          = 1 / (1 + vat) - fee          share of a customer cent that stays (19 % VAT, 2,5 % fee: 0,815)
break-even = cost_net / K                  customer price with zero margin
margin     = price * K - cost_net
price      = ceil_to_cent((cost_net + target_margin) / K)
```

A cent above break-even leaves K cents, not 1 cent. Say so, or "price minus break-even" reads as the margin.

## Tax rules (Germany)

- A shop for consumers must show gross prices (PAngV). Net prices are only for an offer to businesses alone.
- VAT that the supplier charges is deductible. The cost is the net price of the supplier.
- A VAT-free item of the supplier (postage) costs its full price. VAT is still due on the whole resale price.
- Gewerbesteuer and Körperschaftsteuer are taxes on the profit of the company per year, not costs of a unit. Keep them out of the margin. Show them only when asked, as one more step.
- Small-business rule (§ 19 UStG): no VAT on the resale price. Name it as a lever. The tax advisor decides.

## Build the structure

1. Split the supplier price into base + price per unit. Check the split against every row of the list.
2. Find each step where the cost jumps. Each step gets its own base price.
3. Each part must be above its own break-even: every base price and every unit price. A base that only the units carry is a loss in disguise.
4. The margin must not drop when the quantity grows. Check it across each step.
5. No charm ending (x,x9) and no rounding of a total. A published unit price (per page, per option) stays exact. A total is the sum of its parts, so the surcharge of an option is its unit price times the units. A rounded total shows as cents added from nowhere. Round only when the user asks for an ending.
6. Price an option (colour, express) the way its cost behaves: per unit if the cost is per unit. A fixed amount loses on large orders or overcharges small ones.

## Show it

Two tables.

Parts:

| Part | Supplier net | Break-even price (with VAT + payment fee) | Our price | Margin |
| --- | --- | --- | --- | --- |

Per quantity: the quantities that customers really order, plus each step and the maximum.

| Quantity | Break-even | Our price | Margin | Benchmark competitor |
| --- | --- | --- | --- | --- |

- Margin in cents, prices in the currency.
- No column for the current price unless the user asks for it.
- No columns for VAT owed, fee, or "reaches us". They are inside break-even.
- Below the tables: one line per assumption that no invoice confirms, and one line per open decision with a recommendation.

## Checks before you answer

- Is the cost reading confirmed by a real invoice? If not, say so.
- Does an add-on of the supplier (registered mail) use another base price than the main product? Read the clause, do not add the surcharge to the wrong base.
- Does the list hold a maximum (weight, units)? Do not show a quantity above it.
- Compare the margin goal with the current price first. The current price may meet the goal already.

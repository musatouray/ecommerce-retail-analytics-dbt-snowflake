# Business Analytics Impact Summary

## E-Commerce Retail Analytics Platform

**Prepared by:** Data Engineering Team
**Platform:** dbt + Snowflake
**Dataset:** Brazilian E-Commerce (Olist) - 100K+ Orders

---

# Executive Overview

This document showcases **8 advanced analytics patterns** implemented to drive business intelligence and decision-making. Each pattern addresses specific business questions and delivers actionable insights.

| Pattern | Business Question | Key Insight |
|---------|-------------------|-------------|
| RFM Analysis | Who are our best customers? | 12% are Champions worth 2x average |
| Cohort Analysis | How do customers behave over time? | Retention drops to <1% after Month 1 |
| Customer Lifetime Value | How much is each customer worth? | Platinum customers worth $637 each |
| Churn Risk | Who is about to leave? | 46% of customers at Critical risk |
| Pareto Analysis | Which products drive revenue? | 28% of products drive 80% of revenue |
| Time Intelligence | How are we trending? | 7-day moving average smooths volatility |
| Funnel Analysis | Where do we lose orders? | 97% delivery rate, 12-day avg delivery |
| Market Basket | What's bought together? | Computer accessories: 7,000+ lift |

---

<div style="page-break-after: always;"></div>

# 1. RFM Analysis

## Business Question
> "Who are our most valuable customers, and how should we engage different segments?"

## What It Measures
- **Recency**: Days since last purchase (are they still engaged?)
- **Frequency**: Number of orders (are they loyal?)
- **Monetary**: Total spending (are they valuable?)

## Sample Output

| Segment | Customers | Avg Revenue | Action |
|---------|-----------|-------------|--------|
| Champions | 11,607 | $308 | Reward & retain |
| Cant Lose Them | 782 | $365 | Win back immediately |
| Potential Loyalists | 10,211 | $169 | Nurture to Champions |
| At Risk | 3,127 | $172 | Re-engagement campaign |
| Hibernating | 28,263 | $164 | Low-cost reactivation |

## Visualization

```
Customer Segments by Value

Champions        ████████████████████████████████████  $308
Cant Lose Them   ██████████████████████████████████████ $365
At Risk          ███████████████████  $172
Pot. Loyalists   ███████████████████  $169
Hibernating      ██████████████████   $164
                 $0        $100       $200       $300    $400
                          Average Revenue per Customer
```

## Business Impact
- **Targeted Marketing**: Focus 70% of budget on Champions + Potential Loyalists
- **Retention Priority**: "Cant Lose Them" segment has highest value - prioritize win-back
- **Cost Efficiency**: Reduce spend on Hibernating customers (low ROI)

---

<div style="page-break-after: always;"></div>

# 2. Cohort Analysis

## Business Question
> "How do customers acquired in different months behave over their lifecycle?"

## What It Measures
- **Cohort**: Customers grouped by first purchase month
- **Retention Rate**: % still active in each subsequent month
- **Churn Pattern**: When do customers stop buying?

## Sample Output

| Cohort | Month 0 | Month 1 | Month 2 | Month 3 | Month 4 |
|--------|---------|---------|---------|---------|---------|
| Jan-17 | 100% (754) | 0.4% | 0.3% | 0.1% | 0.4% |
| Feb-17 | 100% (1,705) | 0.2% | 0.3% | 0.1% | 0.2% |
| Mar-17 | 100% (2,521) | 0.3% | 0.2% | 0.2% | 0.1% |

## Visualization

```
Retention Curve by Cohort (% Active)
100% ┤■ ■ ■ ■ ■ ■
     │
 80% ┤
     │
 60% ┤
     │
 40% ┤
     │
 20% ┤
     │
  1% ┤    ▪ ▪ ▪ ▪ ▪  ← Retention drops sharply after Month 0
     └────┬────┬────┬────┬────┬────
         M0   M1   M2   M3   M4   M5

■ = 100% (first purchase)   ▪ = <1% (returning customers)
```

## Business Impact
- **Critical Insight**: 99%+ of customers never return after first purchase
- **Opportunity**: Even 1% retention improvement = significant revenue
- **Action**: Implement post-purchase engagement within 30 days

---

<div style="page-break-after: always;"></div>

# 3. Customer Lifetime Value (CLV)

## Business Question
> "What is each customer worth over their entire relationship with us?"

## What It Measures
- **Historical CLV**: Total spent to date
- **Predicted CLV**: Expected future value based on cohort behavior
- **CLV Segment**: Platinum, Gold, Silver, Bronze tiers

## Sample Output

| Segment | Customers | Avg Historical | Avg Predicted | Growth Potential |
|---------|-----------|----------------|---------------|------------------|
| Platinum | 9,542 | $637 | $637 | Maintain |
| Gold | 19,084 | $202 | $221 | +9% |
| Silver | 28,626 | $93 | $172 | +85% |
| Bronze | 38,168 | $85 | $161 | +89% |

## Visualization

```
Customer Lifetime Value by Segment

                    Historical CLV    Predicted CLV
                    ─────────────────────────────────
Platinum ($637)     ████████████████████████████████████████
                    ████████████████████████████████████████

Gold ($221)         ████████████████████
                    ██████████████████████  (+9%)

Silver ($172)       █████████
                    █████████████████████████████  (+85%)

Bronze ($161)       ████████
                    ████████████████████████████  (+89%)

                    $0       $200      $400       $600
```

## Business Impact
- **Investment Priority**: Silver/Bronze customers have highest growth potential
- **Platinum Protection**: 10% of customers generate disproportionate value
- **CAC Guidance**: Acquire customers for less than predicted CLV

---

<div style="page-break-after: always;"></div>

# 4. Churn Risk Indicators

## Business Question
> "Which customers are at risk of leaving, and why?"

## What It Measures
- **Recency Risk**: How long since last purchase
- **Frequency Risk**: Single purchasers are higher risk
- **Sentiment Risk**: Low review scores indicate dissatisfaction
- **Combined Score**: 0-100 additive risk model

## Sample Output

| Risk Level | Customers | Avg Days Inactive | Avg Risk Score |
|------------|-----------|-------------------|----------------|
| Critical | 43,586 (46%) | 284 days | 83 |
| High | 41,775 (44%) | 243 days | 64 |
| Medium | 9,699 (10%) | 74 days | 36 |
| Low | 360 (<1%) | 32 days | 9 |

## Visualization

```
Churn Risk Distribution

                    ┌─────────────────────────────────────┐
     Critical (46%) │█████████████████████████████████████│ 83 score
                    └─────────────────────────────────────┘
                    ┌────────────────────────────────────┐
         High (44%) │████████████████████████████████████│ 64 score
                    └────────────────────────────────────┘
                    ┌────────┐
       Medium (10%) │████████│ 36 score
                    └────────┘
                    ┌┐
          Low (<1%) ││ 9 score
                    └┘

     Customers:     0        20K       40K       60K
```

## Business Impact
- **Urgent Action**: 46% at Critical risk = immediate intervention needed
- **Resource Allocation**: Focus retention on High-risk before they become Critical
- **Early Warning**: Medium-risk customers are the intervention sweet spot

---

<div style="page-break-after: always;"></div>

# 5. Pareto Analysis (80/20 Rule)

## Business Question
> "Which products are driving the majority of our revenue?"

## What It Measures
- **Revenue Rank**: Products ordered by revenue contribution
- **Cumulative %**: Running total of revenue
- **ABC Classification**: A (top 80%), B (next 15%), C (final 5%)

## Sample Output

| Segment | Products | Revenue | Cumulative % |
|---------|----------|---------|--------------|
| A (Top 80%) | 9,252 (28%) | $12.7M | 80% |
| B (Next 15%) | 11,759 (36%) | $2.4M | 95% |
| C (Bottom 5%) | 11,940 (36%) | $0.8M | 100% |

## Visualization

```
Pareto Curve: Products vs Revenue

100% ┤                                            ●────●
     │                                       ●────┘
 95% ┤                                  ●────┘
     │                             ●────┘         Segment B
 80% ┤                        ●────┘              (36% products
     │                   ●────┘                    = 15% revenue)
 60% ┤              ●────┘
     │         ●────┘              Segment A
 40% ┤    ●────┘                   (28% products = 80% revenue)
     │●───┘
 20% ┤
     │
  0% └─────┬──────┬──────┬──────┬──────┬──────
          0%    20%    40%    60%    80%   100%
                    % of Products

         ████ = A Products (Focus)
         ▒▒▒▒ = B Products (Monitor)
         ░░░░ = C Products (Review)
```

## Business Impact
- **Inventory Focus**: 28% of products generate 80% of revenue
- **Stock Priority**: Ensure A-segment products never stock out
- **Portfolio Review**: Consider discontinuing low-performing C products

---

<div style="page-break-after: always;"></div>

# 6. Time Intelligence

## Business Question
> "How are we performing compared to last week/month/year?"

## What It Measures
- **Prior Period Comparison**: WoW, MoM, YoY growth rates
- **Moving Averages**: 7-day, 28-day trends (smooths daily noise)
- **Running Totals**: YTD, QTD, MTD cumulative performance

## Sample Output

| Date | Orders | Revenue | WoW Growth | 7-Day MA |
|------|--------|---------|------------|----------|
| Jan 1 | 73 | $8,392 | -19% | $14,001 |
| Jan 2 | 203 | $29,411 | +21% | $14,682 |
| Jan 3 | 222 | $36,746 | +34% | $16,708 |
| Jan 4 | 255 | $39,916 | +75% | $19,537 |
| Jan 5 | 209 | $32,227 | +57% | $21,205 |
| Jan 8 | 292 | $45,169 | +300% | $30,788 |

## Visualization

```
Daily Revenue vs 7-Day Moving Average (Jan 2018)

$50K ┤            ●
     │        ●       ●   ●                    ● = Daily Revenue
$40K ┤      ●   ●   ●                          ─ = 7-Day MA
     │    ●
$30K ┤  ●─────────────────────────────
     │ ─────────                    ──────────
$20K ┤
     │
$10K ┤●
     │
  $0 └──┬───┬───┬───┬───┬───┬───┬───┬───┬──
       1   2   3   4   5   6   7   8   9  10
                    January 2018

Moving average reveals underlying trend despite daily volatility
```

## Business Impact
- **Trend Detection**: 7-day MA shows true growth trajectory
- **Anomaly Detection**: Spikes vs MA indicate unusual events
- **YoY Comparison**: Accounts for seasonality in performance evaluation

---

<div style="page-break-after: always;"></div>

# 7. Funnel Analysis

## Business Question
> "Where are we losing customers in the order fulfillment process?"

## What It Measures
- **Stage Counts**: Orders at each process stage
- **Conversion Rates**: % progressing to next stage
- **Cycle Times**: Average days between stages
- **Drop-off Points**: Where orders fail

## Sample Output

| Month | Orders Placed | Orders Delivered | Delivery Rate | Avg Days |
|-------|---------------|------------------|---------------|----------|
| Jan-17 | 789 | 750 | 95.1% | 13.3 |
| Feb-17 | 1,733 | 1,653 | 95.4% | 13.8 |
| May-17 | 3,660 | 3,545 | 96.9% | 12.0 |
| Jul-17 | 3,969 | 3,872 | 97.6% | 12.2 |

## Visualization

```
Order Fulfillment Funnel

PLACED     ████████████████████████████████████████  100% (3,969)
              │
              ▼ 99% approved
APPROVED   ██████████████████████████████████████    99%
              │
              ▼ 98% shipped
SHIPPED    ████████████████████████████████████      98%
              │
              ▼ 99% delivered
DELIVERED  ██████████████████████████████████        97.6% (3,872)
              │
              ▼ 45% reviewed
REVIEWED   ███████████████                           ~45%


    Avg Cycle Time: 12.2 days (Placed → Delivered)

    Drop-off Analysis:
    ├── 1% fail at approval (payment issues)
    ├── 1% fail at shipping (fulfillment issues)
    └── 1% fail at delivery (logistics issues)
```

## Business Impact
- **High Performance**: 97%+ delivery rate indicates strong operations
- **Bottleneck Identified**: Review rate (45%) is opportunity for engagement
- **SLA Tracking**: 12-day average delivery supports customer expectations

---

<div style="page-break-after: always;"></div>

# 8. Market Basket Analysis

## Business Question
> "What products are frequently purchased together?"

## What It Measures
- **Support**: How often does this pair appear in orders?
- **Confidence**: If customer buys A, what's probability they buy B?
- **Lift**: Is this pair bought together more than random chance?

## Sample Output

| Category A | Category B | Co-Purchases | Confidence | Lift |
|------------|------------|--------------|------------|------|
| Computers | Computers | 6 | 67% | 7,309 |
| Computers | Computers | 5 | 63% | 6,167 |
| Bed/Bath | Bed/Bath | 6 | 40% | 3,289 |
| Auto | Auto | 6 | 24% | 623 |
| Auto | Auto | 17 | 19% | 337 |

## Visualization

```
Product Association Strength (Lift)

Lift > 1 = Products bought together MORE than random chance
Lift = 1 = No association (random)
Lift < 1 = Products bought together LESS than expected

                                                    Lift Score
Computer Accessories │████████████████████████████████│ 7,309
(same category)      │                                │
                     │                                │
Bed & Bath          │███████████████                  │ 3,289
(same category)      │                                │
                     │                                │
Auto Parts          │███████                          │ 623
(same category)      │                                │
                     │                                │
Garden Tools        │█                                │ 10
(same category)      │                                │
                     └────────────────────────────────┘
                     1        1000      3000     7000+


Key Insight: Same-category products have highest affinity
             Computer accessories buyers often buy multiple items
```

## Business Impact
- **Bundle Opportunities**: Create packages from high-lift pairs
- **Cross-Sell**: "Customers who bought X also bought Y" recommendations
- **Store Layout**: Place high-affinity products near each other

---

<div style="page-break-after: always;"></div>

# Technical Implementation

## Platform Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      DATA PLATFORM                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐ │
│   │  RAW    │───▶│ STAGING │───▶│  INT    │───▶│  MARTS  │ │
│   │ (CSV)   │    │ (Clean) │    │ (Join)  │    │ (Serve) │ │
│   └─────────┘    └─────────┘    └─────────┘    └─────────┘ │
│                                                             │
│   Source Data    Type Cast      Enrich        Analytics    │
│   100K+ Orders   Deduplicate    Aggregate     8 Patterns   │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│  Technologies: Snowflake (Warehouse) + dbt (Transformation) │
└─────────────────────────────────────────────────────────────┘
```

## Models Delivered

| Layer | Model Count | Purpose |
|-------|-------------|---------|
| Staging | 9 models | Clean and type source data |
| Intermediate | 2 models | Join and enrich |
| Marts - Core | 7 models | Shared dimensions & facts |
| Marts - Customer | 4 models | RFM, Cohort, CLV, Churn |
| Marts - Finance | 3 models | Time Series, Pareto, Payments |
| Marts - Marketing | 3 models | Basket, Category, Geography |
| **Total** | **28 models** | End-to-end pipeline |

## Data Quality

- **100+ Tests**: Uniqueness, not-null, relationships, accepted values
- **Documentation**: Full column descriptions and lineage
- **Version Control**: Git-based change management

---

<div style="page-break-after: always;"></div>

# Summary: Business Value Delivered

## Analytics Capabilities

| Capability | Enables |
|------------|---------|
| Customer Segmentation | Targeted marketing campaigns |
| Retention Analysis | Proactive churn prevention |
| Lifetime Value | Customer acquisition budgeting |
| Product Prioritization | Inventory optimization |
| Trend Analysis | Executive dashboards |
| Process Monitoring | Operational excellence |
| Recommendation Engine | Revenue uplift |

## Key Metrics at a Glance

| Metric | Value | Insight |
|--------|-------|---------|
| Total Customers | 95,420 | Analyzed and segmented |
| Champions | 11,607 (12%) | High-value, engaged |
| Critical Churn Risk | 43,586 (46%) | Requires intervention |
| A-Segment Products | 9,252 (28%) | Drive 80% of revenue |
| Delivery Rate | 97%+ | Strong operations |
| Product Pairs | 22 | Cross-sell opportunities |

## Ready for Production

This analytics platform is:
- **Scalable**: Handles 100K+ orders, designed for growth
- **Maintainable**: Modular dbt models with tests
- **Documented**: Full lineage and business definitions
- **Actionable**: Insights tied to business decisions

---

*Generated from E-Commerce Retail Analytics Platform*
*Built with dbt + Snowflake*

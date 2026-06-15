<img width="1252" height="735" alt="image" src="https://github.com/user-attachments/assets/50596263-bdd4-474c-9fc7-e556d27365bb" /># Advanced E-Commerce & User Behavioral Analytics Engine (MySQL)

## 📌 Project Overview
This repository contains a production-grade relational database framework designed to track, model, and extract actionable business intelligence from large-scale e-commerce transactions and digital clickstream web logs.

The project demonstrates advanced database design, query optimization, namespace collision mitigation, and complex analytical transformations using **MySQL 8.0+**. It is structured specifically to simulate a real-world enterprise data warehouse environment.

---

## 📐 Relational Schema & Architecture (ERD)
<img width="1252" height="735" alt="e-commerce" src="https://github.com/user-attachments/assets/aa28a931-479a-4e03-b911-ee67fc310ff5" />

### ⚡ Performance Optimization Layer
To ensure sub-second response times on tables containing millions of rows, the following indexing strategy is deployed:
*   `idx_orders_date` on `orders(order_date)`: Eliminates full-table scans during temporal cohort slicing.
*   `idx_web_logs_timestamp` on `web_logs(event_timestamp)`: Optimises high-frequency digital session funnel calculations.
*   `idx_order_items_prod` on `order_items(product_id)`: Accelerates cross-selling affinity queries and join operations.

---

## 🚀 Key SQL Concepts Demonstrated
*   **Granularity Consolidation:** Mitigating logical windowing errors across multi-item transactions by abstracting line-items up to order-level schemas before structural ranking.
*   **Multi-Stage Aggregations:** Utilizing Common Table Expressions (CTEs) to consolidate data across granularity layers before analytical ranking.
*   **Advanced Window Functions:** Implementing deep analytics using positional flags (`LAG`, `LEAD`), structural rankings (`DENSE_RANK`, `ROW_NUMBER`), and bounded frames (`ROWS BETWEEN`).
*   **Matrix Pivoting:** Executing dynamic row-to-column evaluations via conditional logic (`CASE WHEN`) for unified customer profiling.
*   **Recursive Operations:** Deploying `WITH RECURSIVE` to simulate cyclical data processing paths and real-time ledger loops.

---

## 📊 Analytical Portfolio Queries Included

The file `analytical_queries.sql` contains **15 end-to-end business-driven scripts** optimized for MySQL execution, categorized across three strategic operational layers:

### Phase 1: Aggregations & Retention Metrics
1. **Month-over-Month (MoM) Growth:** Tracking corporate revenue trajectory.
2. **User Retention Cohorts:** Slicing platform engagement by First vs. Repeat checkouts.
3. **Product Affinity Matrix:** Self-joining transaction tables to discover cross-selling opportunities.
4. **Top Country Transactors:** Using `DENSE_RANK` to isolate high-value geographic segments.
5. **Onboarding Efficiency:** Calculating average conversion times between signup and first transaction.

### Phase 2: Session Clickstream & Funnel Depth
6. **Rolling Order Moving Averages:** Using window frames to isolate user spending trends over time.
7. **The Pareto Principle (80/20 Rule):** Dynamically identifying the top 20% of products driving revenue.
8. **Digital Checkout Funnels:** Mapping click-through leaks across view, add-to-cart, and buy actions.
9. **Consecutive Activity Logging:** Isolation of high-stickiness users active on successive calendar days.
10. **Cart Abandonment Tracking:** Identifying high-friction inventory items drop-offs.

### Phase 3: Advanced Data Manipulation
11. **RFM Scoring Engine:** Assigning statistical Recency, Frequency, and Monetary scores via `NTILE(5)`.
12. **Inventory Balance Recursion:** Simulating progressive warehouse stock reductions.
13. **GDPR Data Anonymization Engine:** Masking customer identities using advanced string manipulation (`SUBSTRING`, `LOCATE`).
14. **Correlated Integrity Audits:** Pinpointing tracking log anomalies with multi-layered subqueries.
15. **Pipeline Lifecycle Tracking:** Calculating absolute execution durations using `TIMESTAMPDIFF`.

---

## 📈 Deep-Dive Business Case Studies & Query Interpretations

### Case Study A: The Corporate Growth Engine (Query 1 - MoM Revenue)
*   **The Business Problem:** Executive leadership needs to verify if marketing spend in Q1 2026 yielded compounding revenue growth or if performance is stalling.
*   **The Technical Approach:** Utilized a native MySQL windowing expression containing `LAG()` over a time-bucketed `DATE_FORMAT` aggregation.
*   **Actionable Insight:** By calculating the exact delta percentage, the data team can isolate whether low revenue is caused by a drop in average order value (AOV) or a drop in physical checkout volume.

### Case Study B: Platform Leakage Tracking (Query 8 & 10 - Clickstream Funnel & Abandonment)
*   **The Business Problem:** The Product team noticed a significant drop-off in user conversion but could not pinpoint if the bottleneck was a high pricing friction point or a broken user interface (UI) checkout button.
*   **The Technical Approach:** Combined transactional table receipts with application event logs (`web_logs`) using an aggressive `LEFT JOIN` strategy. Deployed conditional `COUNT(CASE WHEN...)` matrices to build an absolute conversion funnel.
*   **Actionable Insight:** Products displaying a high `total_cart_additions` metric alongside a near-zero `confirmed_purchased_items` volume pinpoint precise pricing errors or stock allocation discrepancies.

---



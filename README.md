The query analyzes orders made by active users after 2023-06-07 and for each category returns
- product category 
- client with the min number of orders
- client with the max number of orders

--unoptimized--
Time 1370.056 ms

It joins and calculations repeated several times (it searched for the min client and the max client for each product category)

--indexes--

Indexes used to help filter orders by date, join tables faster, filter active clients, work with product categories

--optimized--
Time 685.791 ms

Optimized with CTE and window function

CTE
filtered_orders — select only client id, full name, product category
client_count — how many orders per client in each category
client_rate — rate clients inside each  category

The query use joins to calculate how many orders each active client made in each category
opt_orders (client id, product id, order date)
opt_clients (client name and filter only active clients)
opt_products (product category)

group by to calculate total orders for each client in each  category

row_number(window func) find the client with the minimum and maximum number of orders

partition by product_category to start rancing for every category.

Overall, twice faster execution time

default — 752 ms
seq Scan disabled — 720 ms because used indexes
hash Join disabled — 1047 ms because used slower merge join

--not optimized--
--1370.056 ms--
explain analyze
select
    categories.product_category,
    (
        select concat(full_name, ',', total_orders, ' orders')
        from (
            select
                c.id as client_id,
                concat(c.name, ' ', c.surname) as full_name,
                count(*) as total_orders
            from opt_orders as o
            join opt_products as p
                on o.product_id = p.product_id
            join opt_clients as c
                on o.client_id = c.id
            where o.order_date >= date '2023-06-07'
              and c.status = 'active'
              and p.product_category = categories.product_category
            group by
                c.id,
                concat(c.name, ' ', c.surname)
        ) as client_count
        order by
            total_orders,
            client_id
        limit 1
    ) as min_client,

    (
        select concat(full_name, ',', total_orders, ' orders')
        from (
            select
                c.id as client_id,
                concat(c.name, ' ', c.surname) as full_name,
                count(*) as total_orders
            from opt_orders as o
            join opt_products as p
                on o.product_id = p.product_id
            join opt_clients as c
                on o.client_id = c.id
            where o.order_date >= date '2023-06-07'
              and c.status = 'active'
              and p.product_category = categories.product_category
            group by
                c.id,
                concat(c.name, ' ', c.surname)
        ) as client_count
        order by
            total_orders desc,
            client_id
        limit 1
    ) as max_client

from (
    select distinct
        p.product_category
    from opt_orders as o
    join opt_products as p
        on o.product_id = p.product_id
    join opt_clients as c
        on o.client_id = c.id
    where o.order_date >= date '2023-06-07'
      and c.status = 'active'
) as categories

order by
    categories.product_category;

--index--
create index idx_opt_orders_order_date
    on opt_orders(order_date);
create index idx_opt_orders_client_id
    on opt_orders(client_id);
create index idx_opt_orders_product_id
    on opt_orders(product_id);
create index idx_opt_clients_status
    on opt_clients(status);

--optimized--
--685.791 ms--
explain analyze
with filtered_orders as (
    select
        c.id as client_id,
        concat(c.name, ' ', c.surname) as full_name,
        p.product_category
    from opt_orders as o
    join opt_products as p
        on o.product_id = p.product_id
    join opt_clients as c
        on o.client_id = c.id
    where o.order_date >= date '2023-06-07'
      and c.status = 'active'
),
client_count as (
    select
        product_category,
        client_id,
        full_name,
        count(*) as total_orders
    from filtered_orders
    group by
        product_category,
        client_id,
        full_name
),
client_rate as (
    select
        product_category,
        full_name,
        total_orders,
        row_number() over (
            partition by product_category
            order by total_orders , client_id
        ) as min_top,
        row_number() over (
            partition by product_category
            order by total_orders desc, client_id
        ) as max_top
    from client_count
)
select
    product_category,
    max(concat(full_name, ',', total_orders, ' orders')) filter (where min_top = 1) as min_client,
    max(concat(full_name, ',', total_orders, ' orders')) filter (where max_top = 1) as max_client
from client_rate
group by
    product_category
order by
    product_category;

--bonus--
--disable seq scans--
--757.494 ms--
set enable_seqscan = off;

explain analyze
with filtered_orders as (
    select
        c.id as client_id,
        concat(c.name, ' ', c.surname) as full_name,
        p.product_category
    from opt_orders as o
    join opt_products as p
        on o.product_id = p.product_id
    join opt_clients as c
        on o.client_id = c.id
    where o.order_date >= date '2023-06-07'
      and c.status = 'active'
),
client_count as (
    select
        product_category,
        client_id,
        full_name,
        count(*) as total_orders
    from filtered_orders
    group by
        product_category,
        client_id,
        full_name
),
client_rate as (
    select
        product_category,
        full_name,
        total_orders,
        row_number() over (
            partition by product_category
            order by total_orders, client_id
        ) as min_top,
        row_number() over (
            partition by product_category
            order by total_orders desc, client_id
        ) as max_top
    from client_count
)
select
    product_category,
    max(concat(full_name, ',', total_orders, ' orders'))
        filter (where min_top = 1) as min_client,
    max(concat(full_name, ',', total_orders, ' orders'))
        filter (where max_top = 1) as max_client
from client_rate
group by product_category
order by product_category;

reset enable_seqscan;

-- disable hash join--
--1042.425 ms--
set enable_hashjoin = off;

explain analyze
with filtered_orders as (
    select
        c.id as client_id,
        concat(c.name, ' ', c.surname) as full_name,
        p.product_category
    from opt_orders as o
    join opt_products as p
        on o.product_id = p.product_id
    join opt_clients as c
        on o.client_id = c.id
    where o.order_date >= date '2023-06-07'
      and c.status = 'active'
),
client_count as (
    select
        product_category,
        client_id,
        full_name,
        count(*) as total_orders
    from filtered_orders
    group by
        product_category,
        client_id,
        full_name
),
client_rate as (
    select
        product_category,
        full_name,
        total_orders,
        row_number() over (
            partition by product_category
            order by total_orders, client_id
        ) as min_top,
        row_number() over (
            partition by product_category
            order by total_orders desc, client_id
        ) as max_top
    from client_count
)
select
    product_category,
    max(concat(full_name, ',', total_orders, ' orders'))
        filter (where min_top = 1) as min_client,
    max(concat(full_name, ',', total_orders, ' orders'))
        filter (where max_top = 1) as max_client
from client_rate
group by product_category
order by product_category;

reset enable_hashjoin;

use sqlproject;
show tables;
SELECT * FROM maindata limit 1000;
SELECT * FROM `maindata` WHERE `Available_seats` IS NULL;
set sql_safe_updates=0;
alter table maindata add column date_column date;
alter table maindata rename column `Month (#)` to `month`;
alter table maindata rename column `# Transported Passengers` to `Transported_passengers`;
alter table maindata rename column `# Available Seats` to `Available_seats`;
alter table maindata rename column  `Carrier Name` to `carrier_name`;
alter table maindata rename column `From - To City` to `from-to-city`;
update maindata set date_column=concat_ws("-",year,month,day);
select date_column from maindata;
alter table maindata add column day_type varchar(10);
update maindata set day_type=(CASE
WHEN (DAYOFWEEK(date_column) IN (1 , 7)) THEN 'Weekend'
ELSE 'Weekday'
END);

alter table maindata rename column `%Distance Group ID` to `distance_id`;
alter table maindata rename column `%Airline ID` to `airline_id`;
alter table distance_groups rename column `%Distance Group ID` to `distance_id`;
alter table distance_groups rename column `Distance Interval` to `distance_interval`;

-- Q1
CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`localhost` 
    SQL SECURITY DEFINER
VIEW `date_table` AS
    SELECT 
        `maindata`.`date_column` AS `date_column`,
        YEAR(`maindata`.`date_column`) AS `year`,
        MONTH(`maindata`.`date_column`) AS `month_no`,
        MONTHNAME(`maindata`.`date_column`) AS `month_name`,
        QUARTER(`maindata`.`date_column`) AS `quarter`,
        DATE_FORMAT(`maindata`.`date_column`, '%Y-%M') AS `yearmonth`,
        DAYOFWEEK(`maindata`.`date_column`) AS `weekday_number`,
        DAYNAME(`maindata`.`date_column`) AS `weekday_name`,
        MONTH((`maindata`.`date_column` + INTERVAL -(3) MONTH)) AS `financial_month`,
        QUARTER((`maindata`.`date_column` + INTERVAL -(3) MONTH)) AS `financial_quarter`
    FROM
        `maindata`;

-- Q2

CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`localhost` 
    SQL SECURITY DEFINER
VIEW `yqm_lf` AS
    SELECT 
        `year_query`.`yr` AS `yr`,
        `quarter_query`.`Q` AS `Q`,
        `month_query`.`mno` AS `mno`,
        `year_query`.`lf` AS `ylf`,
        `quarter_query`.`lf` AS `qlf`,
        `month_query`.`lf` AS `mlf`
    FROM
        (((SELECT 
            YEAR(`maindata`.`date_column`) AS `yr`,
                ROUND((AVG(IFNULL((`maindata`.`Transported_passengers` / `maindata`.`Available_seats`), 0)) * 100), 2) AS `lf`
        FROM
            `maindata`
        GROUP BY `yr`) `year_query`
        LEFT JOIN (SELECT 
            YEAR(`maindata`.`date_column`) AS `yr`,
                QUARTER(`maindata`.`date_column`) AS `Q`,
                ROUND((AVG(IFNULL((`maindata`.`Transported_passengers` / `maindata`.`Available_seats`), 0)) * 100), 2) AS `lf`
        FROM
            `maindata`
        GROUP BY `yr` , `Q`) `quarter_query` ON ((`year_query`.`yr` = `quarter_query`.`yr`)))
        LEFT JOIN (SELECT 
            YEAR(`maindata`.`date_column`) AS `yr`,
                MONTH(`maindata`.`date_column`) AS `mno`,
                ROUND((AVG(IFNULL((`maindata`.`Transported_passengers` / `maindata`.`Available_seats`), 0)) * 100), 2) AS `lf`
        FROM
            `maindata`
        GROUP BY `yr` , `mno`) `month_query` ON ((`year_query`.`yr` = `month_query`.`yr`)))
    ORDER BY `year_query`.`yr` , `quarter_query`.`Q` , `month_query`.`mno`;
    
    -- Q3
    CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`localhost` 
    SQL SECURITY DEFINER
VIEW `carrier_lf` AS
    SELECT 
        `maindata`.`carrier_name` AS `carrier_name`,
        ROUND((AVG(IFNULL((`maindata`.`Transported_passengers` / `maindata`.`Available_seats`),
                        0)) * 100),
                2) AS `lf`
    FROM
        `maindata`
    GROUP BY `maindata`.`carrier_name`
    ORDER BY `lf` DESC;
    
    -- Q4
    CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`localhost` 
    SQL SECURITY DEFINER
VIEW `top_10_carriers` AS
    SELECT 
        `maindata`.`carrier_name` AS `carrier_name`,
        SUM(`maindata`.`Transported_passengers`) AS `sum(transported_passengers)`
    FROM
        `maindata`
    GROUP BY `maindata`.`carrier_name`
    ORDER BY SUM(`maindata`.`Transported_passengers`) DESC
    LIMIT 10;
    
    -- Q5
    CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`localhost` 
    SQL SECURITY DEFINER
VIEW `top_routes` AS
    SELECT 
        `maindata`.`From-To-City` AS `from-to-city`,
        COUNT(`maindata`.`From-To-City`) AS `count_from_to_city`
    FROM
        `maindata`
    GROUP BY `maindata`.`from-To-City`
    ORDER BY `count_from_to_city` DESC
    LIMIT 15;
    
    -- Q6
    CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`localhost` 
    SQL SECURITY DEFINER
VIEW `day_type_lf` AS
    SELECT 
        `maindata`.`day_type` AS `day_type`,
        ROUND((AVG(IFNULL((`maindata`.`Transported_passengers` / `maindata`.`Available_seats`),
                        0)) * 100),
                2) AS `dlf`
    FROM
        `maindata`
    GROUP BY `maindata`.`day_type`;
    
    -- Q8
    CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`localhost` 
    SQL SECURITY DEFINER
VIEW `distance` AS
    SELECT 
        `distance_groups`.`distance_id` AS `distance_id`,
        `distance_groups`.`distance_interval` AS `distance_interval`,
        COUNT(`maindata`.`airline_id`) AS `count(airline_id)`
    FROM
        (`distance_groups`
        LEFT JOIN `maindata` ON ((`distance_groups`.`distance_id` = `maindata`.`distance_id`)))
    GROUP BY `distance_groups`.`distance_id` , `distance_groups`.`distance_interval`;
    
select * from date_table;
select * from yqm_lf;
select * from carrier_lf;
select * from top_10_carriers;
select * from top_routes;
select * from day_type_lf;
select * from distance;

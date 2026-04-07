-- SQL bot 10
SELECT max(years_employed) FROM employees;
SELECT role, avg(years_employed) FROM employees GROUP BY role;
SELECT building, sum(years_employed) FROM employees GROUP BY building;

-- SQL bot 11
SELECT role, count(*) FROM employees WHERE role == "Artist";
SELECT role, count(*) FROM employees GROUP BY role;
SELECT sum(years_employed) FROM employees WHERE role == "Engineer";

-- FreeSQL exercises
select shape, sum(weight) as number_of_shapes,
       stddev(distinct weight) distinct_weight_stddev
from   bricks
group by shape;


select shape, sum(weight) as shape_weight
from   bricks
GROUP BY shape;


select shape, sum ( weight )
from   bricks
group  by shape HAVING sum(weight) < 4;

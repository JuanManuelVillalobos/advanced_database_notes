-- FreeSQL
select colour from my_brick_collection
UNION
select colour from your_brick_collection
order by colour;


select shape from my_brick_collection
EXCEPT
select shape from your_brick_collection;

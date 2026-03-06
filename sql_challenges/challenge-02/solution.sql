-- SQL Lesson 6: Multi-table queries with JOINs
SELECT title, domestic_sales, international_sales 
FROM movies
  JOIN boxoffice
    ON movies.id = boxoffice.movie_id;

SELECT title, domestic_sales, international_sales
FROM movies
  JOIN boxoffice
    ON movies.id = boxoffice.movie_id
WHERE international_sales > domestic_sales;

SELECT title, rating
FROM movies
  JOIN boxoffice
    ON movies.id = boxoffice.movie_id
ORDER BY rating DESC;


-- SQL Lesson 7: OUTER JOINs
SELECT DISTINCT building FROM employees;
SELECT * FROM buildings;
SELECT DISTINCT building_name, role 
FROM buildings 
  LEFT JOIN employees
    ON building_name = building;



-- Page With No Likes
select p.page_id
from pages p
left join page_likes pl
  on p.page_id = pl.page_id
where pl.page_id is null
order by p.page_id asc;
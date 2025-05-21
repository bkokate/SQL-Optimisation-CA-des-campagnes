
#SEGMENTATION DES CLIENTS
  #Montant dépensé par tranche d'âge
SELECT
    CASE
      WHEN DATE_DIFF(CURRENT_DATE(), clients.birthday_date, YEAR) < 30 THEN '0-29'
      WHEN DATE_DIFF(CURRENT_DATE(), clients.birthday_date, YEAR) BETWEEN 30 AND 49 THEN '30-49'
      WHEN DATE_DIFF(CURRENT_DATE(), clients.birthday_date, YEAR) BETWEEN 50 AND 69 THEN '50-69'
      ELSE '70+'
    END AS age_range,
    AVG(items.unit_price * orders.quantity) AS average_spent
  FROM
    `data.clients` AS clients
    INNER JOIN `data.orders` AS orders ON clients.id = CAST(orders.client_id as INT64)
    INNER JOIN `data.items` AS items ON orders.item_id = CAST(items.id as STRING)
  GROUP BY 1;

#Répartition des clients actifs ou inactif
SELECT 
  CASE 
    WHEN total_orders > 0 THEN 'Actifs'
    ELSE 'Inactifs'
  END AS statut_client,
  COUNT(client_id) AS nombre_clients
FROM (
  SELECT 
    clients.id AS client_id,
    COUNT(orders.id) AS total_orders
  FROM 
    `data.clients` clients
  LEFT JOIN 
    `data.orders` orders
    ON clients.id = CAST(orders.client_id AS INT64)
  GROUP BY 
    clients.id
)
GROUP BY 
  statut_client
ORDER BY 
  nombre_clients DESC;

  #Top 1O clients par revenue
  SELECT 
  clients.id AS client_id,
  clients.firstname,
  clients.lastname,
  clients.region,
  SUM(orders.quantity * items.unit_price) AS total_revenue
FROM 
  `data.clients` clients
LEFT JOIN 
  `data.orders` orders
  ON clients.id = CAST(orders.client_id AS INT64)
LEFT JOIN 
  `data.items` items
  ON orders.item_id = CAST(items.id AS STRING)
GROUP BY 
  clients.id, clients.firstname, clients.lastname, clients.region
ORDER BY 
  total_revenue DESC
LIMIT 10;

#CAMPAGNES ET CHIFFRES D'AFFAIRE
  #Chiffre d'affaire par campagne
WITH orders_grouped AS (
  SELECT 
    CAST(item_id AS INT64) AS item_id,  -- Convertir item_id en INT64
    SUM(quantity) AS total_quantity, 
    ordered_at
  FROM 
    `data.orders`
  GROUP BY 
    item_id, ordered_at
)
SELECT 
  c.name AS campagne_nom, 
  c.start_date, 
  c.end_date, 
  c.discount, 
  DATE_DIFF(c.end_date, c.start_date, DAY) AS nombre_de_jours, 
  SUM(og.total_quantity * i.unit_price) AS chiffre_affaire
FROM 
  `data.campaigns` c
JOIN 
  orders_grouped og
ON 
  og.ordered_at BETWEEN c.start_date AND c.end_date
JOIN 
  `data.items` i
ON 
  og.item_id = i.id  -- Jointure sur item_id converti en INT64
GROUP BY 
  c.name, c.start_date, c.end_date, c.discount
ORDER BY 
  c.start_date ASC;

#Chiffre d'affaire sur 2020
WITH orders_grouped AS (
  SELECT 
    CAST(item_id AS INT64) AS item_id, 
    SUM(quantity) AS quantite_totale
  FROM 
    `data.orders`
  WHERE 
    ordered_at BETWEEN '2020-01-01' AND '2020-11-05'  
  GROUP BY 
    item_id
)
SELECT 
  i.id AS produit_id, 
  i.name AS produit_nom, 
  i.unit_price AS prix_unitaire, 
  og.quantite_totale, 
  ROUND(og.quantite_totale * i.unit_price, 2) AS chiffre_affaire
FROM 
  orders_grouped og
JOIN 
  `data.items` i
ON 
  i.id = og.item_id
UNION ALL
SELECT 
  NULL AS produit_id, 
  'Total' AS produit_nom, 
  NULL AS prix_unitaire, 
  SUM(og.quantite_totale) AS quantite_totale, 
  ROUND(SUM(og.quantite_totale * items.unit_price), 2) AS chiffre_affaire
FROM 
  orders_grouped og
JOIN 
  `data.items` items
ON 
  items.id = og.item_id
ORDER BY 
  chiffre_affaire DESC;





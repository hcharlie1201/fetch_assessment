run 
```console
$ docker ps
$ docker-compose build
$ docker-compose up
```


Test the API

```
curl -X POST http://localhost:3000/receipts/process \
  -H "Content-Type: application/json" \
  -d '{
    "retailer": "M&M Corner Market",
    "purchaseDate": "2022-03-20",
    "purchaseTime": "14:33",
    "items": [
      {
        "shortDescription": "Gatorade",
        "price": "2.25"
      },
      {
        "shortDescription": "Gatorade",
        "price": "2.25"
      }
    ],
    "total": "4.50"
  }'
```


```
curl http://localhost:3000/receipts/[id]/points
```

const express = require('express');
const app = express();
const port = 8400;

const AWS = require('aws-sdk');

AWS.config.update({ region: 'eu-west-1' }); // Update to your region

const dynamoDB = new AWS.DynamoDB.DocumentClient();
const tableName = 'practice';

app.use(express.json());

app.get('/', (req, res) => {
  // inject a random delay 30% of the time
  if (Math.random() <= 0.3) {
    const sleepTime = Math.random() * (3000 - 500) + 500;
    setTimeout(() => {
      res.json({ message: 'hello world' });
    }, sleepTime);
  } else {
    res.json({ message: 'hello world' });
  }
});

app.listen(port, () => {
  console.log(`Server is running on http://localhost:${port}`);
});

// basically 80% of the time this server is "working"
const is_server_working = Math.random() >= 0.2;

app.get('/healthz', (req, res) => {
  if (is_server_working) {
    res.status(200).send('OK');
  } else {
    res.status(500).send('NOT OK');
  }
});

// Route to read from DynamoDB
app.get('/read/:id', (req, res) => {
  const params = {
    TableName: tableName,
    Key: {
      id: req.params.id
    }
  };

  dynamoDB.get(params, (err, data) => {
    if (err) {
      console.error("Unable to read item. Error JSON:", JSON.stringify(err, null, 2));
      res.status(500).json({ error: 'Could not read from DynamoDB' });
    } else {
      console.log("GetItem succeeded:", JSON.stringify(data, null, 2));
      res.status(200).json(data.Item);
    }
  });
});


app.post('/write', (req, res) => {
  const params = {
    TableName: tableName,
    Item: {
      id: req.body.id, // Ensure your request has an 'id' field
      data: req.body.data // Ensure your request has a 'data' field
    }
  };

  dynamoDB.put(params, (err, data) => {
    if (err) {
      console.error("Unable to add item. Error JSON:", JSON.stringify(err, null, 2));
      res.status(500).json({ error: 'Could not write to DynamoDB' });
    } else {
      console.log("Added item:", JSON.stringify(data, null, 2));
      res.status(200).json({ message: 'Data written to DynamoDB' });
    }
  });
});
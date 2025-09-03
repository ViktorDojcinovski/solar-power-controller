import http from "node:http";

const port = process.env.PORT || 3000;
const server = http.createServer((req, res) => {
  if (req.url === "/health") {
    res.writeHead(200);
    return res.end("ok");
  }
  res.writeHead(200, { "Content-Type": "application/json" });
  res.end(JSON.stringify({ message: "hello from ECS" }));
});
server.listen(port, () => console.log(`listening on ${port}`));

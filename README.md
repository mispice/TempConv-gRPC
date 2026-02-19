# Temperature Converter - gRPC + Protocol Buffers

A distributed temperature conversion service built with **Go**, **gRPC**, **Protocol Buffers**, and **Flutter Web**.

## 🌡️ Features

- **Celsius to Fahrenheit** conversion
- **Fahrenheit to Celsius** conversion
- Real-time gRPC communication
- Professional dark-themed UI
- Containerized microservices architecture
- Kubernetes-ready deployment

## 🏗️ Architecture

```
┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│   Flutter    │ ───▶ │  grpcwebproxy│ ───▶ │   Go gRPC    │
│   Frontend   │      │   (port 8081)│      │   Backend    │
│  (port 80)   │ ◀─── │              │ ◀─── │  (port 50051)│
└──────────────┘      └──────────────┘      └──────────────┘
```

## 📁 Project Structure

```
TempConv-gRPC/
├── proto/
│   ├── temperature.proto          # Protocol Buffers definition
│   ├── temperature.pb.go          # Generated Go code
│   └── temperature_grpc.pb.go     # Generated gRPC code
├── server/
│   └── main.go                    # Go gRPC server implementation
├── frontend/
│   ├── lib/
│   │   ├── main.dart              # Flutter UI
│   │   └── proto/                 # Generated Dart proto files
│   ├── web/                       # Web assets
│   └── pubspec.yaml               # Flutter dependencies
├── Dockerfile.backend             # Backend container
├── Dockerfile.frontend            # Frontend container
├── Dockerfile.proxy               # Proxy container
└── go.mod                         # Go dependencies
```

## 🚀 Quick Start

### Prerequisites

- Go 1.21+
- Flutter 3.2.6+
- Protocol Buffers compiler (`protoc`)
- grpcwebproxy

### Local Development

1. **Start the backend:**
```bash
cd server
go run main.go
# Server listening on :50051
```

2. **Start the grpcwebproxy:**
```bash
grpcwebproxy \
  --backend_addr=localhost:50051 \
  --run_tls_server=false \
  --allow_all_origins \
  --server_http_debug_port=8081
```

3. **Start the frontend:**
```bash
cd frontend
flutter pub get
flutter run -d chrome
```

## 🐳 Docker Deployment

### Build Images

```bash
# Backend
docker build -t tempconv-backend:v1 -f Dockerfile.backend .

# Proxy
docker build -t tempconv-proxy:v1 -f Dockerfile.proxy .

# Frontend
docker build -t tempconv-frontend:v1 -f Dockerfile.frontend .
```

### Run with Docker Compose (optional)

```yaml
version: '3.8'
services:
  backend:
    image: tempconv-backend:v1
    ports:
      - "50051:50051"
  
  proxy:
    image: tempconv-proxy:v1
    ports:
      - "8081:8081"
    depends_on:
      - backend
  
  frontend:
    image: tempconv-frontend:v1
    ports:
      - "8080:80"
    depends_on:
      - proxy
```

## ☸️ Kubernetes Deployment

### Deploy to GKE

1. **Build and push to Google Artifact Registry:**
```bash
# Backend
gcloud builds submit --config=cloudbuild-backend.yaml .

# Proxy
gcloud builds submit --config=cloudbuild-proxy.yaml .

# Frontend
gcloud builds submit --config=cloudbuild-frontend.yaml .
```

2. **Apply Kubernetes manifests:**
```bash
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/proxy-deployment.yaml
kubectl apply -f k8s/frontend-deployment.yaml
kubectl apply -f k8s/ingress.yaml
```

3. **Get external IP:**
```bash
kubectl get ingress tempconv-ingress
```

## 📡 API Documentation

### Proto Definition

```protobuf
service TemperatureConverter {
  rpc ConvertToFahrenheit(TemperatureRequest) returns (TemperatureResponse);
  rpc ConvertToCelsius(TemperatureRequest) returns (TemperatureResponse);
}

message TemperatureRequest {
  double value = 1;
}

message TemperatureResponse {
  double value = 1;
  string unit = 2;
  string formula = 3;
}
```

### Conversion Formulas

- **Celsius → Fahrenheit:** `°F = (°C × 9/5) + 32`
- **Fahrenheit → Celsius:** `°C = (°F - 32) × 5/9`

## 🛠️ Technology Stack

- **Backend:** Go 1.21, gRPC v1.56.3
- **Frontend:** Flutter 3.16+, Dart 3.2+
- **Protocol:** Protocol Buffers (proto3)
- **Proxy:** grpcwebproxy (gRPC-Web bridge)
- **Containerization:** Docker, multi-stage builds
- **Orchestration:** Kubernetes (GKE)

## 📊 Example Usage

### gRPC Request (Go client)

```go
client := pb.NewTemperatureConverterClient(conn)
req := &pb.TemperatureRequest{Value: 100}
resp, _ := client.ConvertToFahrenheit(context.Background(), req)
fmt.Printf("Result: %.2f %s\n", resp.Value, resp.Unit)
// Output: Result: 212.00 °F
```

### Web UI

1. Navigate to `http://localhost:8080` (or your deployment URL)
2. Enter temperature value
3. Click "Convert to Fahrenheit" or "Convert to Celsius"
4. View result with conversion formula

## 🔧 Development

### Regenerate Proto Files

**Go:**
```bash
protoc --go_out=. --go_opt=paths=source_relative \
       --go-grpc_out=. --go-grpc_opt=paths=source_relative \
       proto/temperature.proto
```

**Dart:**
```bash
protoc --dart_out=grpc:frontend/lib/proto \
       -I proto proto/temperature.proto
```

## 📝 License

MIT License - feel free to use for educational purposes

## 👨‍💻 Author

Built as a distributed systems assignment demonstrating gRPC and Protocol Buffers

---

**Live Demo:** [Coming soon after deployment]

package main

import (
	"context"
	"log"
	"net"

	pb "github.com/mispice/TempConv-gRPC/proto"
	"google.golang.org/grpc"
)

type temperatureServer struct {
	pb.UnimplementedTemperatureConverterServer
}

// ConvertToFahrenheit converts Celsius to Fahrenheit
func (s *temperatureServer) ConvertToFahrenheit(ctx context.Context, req *pb.TemperatureRequest) (*pb.TemperatureResponse, error) {
	celsius := req.Value
	fahrenheit := (celsius * 9 / 5) + 32
	
	return &pb.TemperatureResponse{
		Value:   fahrenheit,
		Unit:    "°F",
		Formula: "°F = (°C × 9/5) + 32",
	}, nil
}

// ConvertToCelsius converts Fahrenheit to Celsius
func (s *temperatureServer) ConvertToCelsius(ctx context.Context, req *pb.TemperatureRequest) (*pb.TemperatureResponse, error) {
	fahrenheit := req.Value
	celsius := (fahrenheit - 32) * 5 / 9
	
	return &pb.TemperatureResponse{
		Value:   celsius,
		Unit:    "°C",
		Formula: "°C = (°F - 32) × 5/9",
	}, nil
}

func main() {
	lis, err := net.Listen("tcp", ":50051")
	if err != nil {
		log.Fatalf("Failed to listen: %v", err)
	}

	grpcServer := grpc.NewServer()
	pb.RegisterTemperatureConverterServer(grpcServer, &temperatureServer{})

	log.Println("Temperature Converter gRPC server listening on :50051")
	if err := grpcServer.Serve(lis); err != nil {
		log.Fatalf("Failed to serve: %v", err)
	}
}

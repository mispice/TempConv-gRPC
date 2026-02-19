import 'package:flutter/material.dart';
import 'package:grpc/grpc_web.dart';
import 'proto/temperature.pbgrpc.dart';

void main() {
  runApp(const TempConverterApp());
}

class TempConverterApp extends StatelessWidget {
  const TempConverterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Temperature Converter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFFF6B35),
          secondary: const Color(0xFF00D9FF),
          surface: const Color(0xFF1E1E2E),
          background: const Color(0xFF121212),
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF1E1E2E),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B35),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2A2A3E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2),
          ),
        ),
      ),
      home: const TempConverterHome(),
    );
  }
}

class TempConverterHome extends StatefulWidget {
  const TempConverterHome({super.key});

  @override
  State<TempConverterHome> createState() => _TempConverterHomeState();
}

class _TempConverterHomeState extends State<TempConverterHome> {
  late TemperatureConverterClient _client;
  final TextEditingController _celsiusController = TextEditingController();
  final TextEditingController _fahrenheitController = TextEditingController();
  String _celsiusResult = '';
  String _fahrenheitResult = '';
  String _celsiusFormula = '';
  String _fahrenheitFormula = '';

  @override
  void initState() {
    super.initState();
    const proxyUrl = String.fromEnvironment('GRPC_PROXY_URL', defaultValue: 'http://localhost:8081');
    
    final channel = GrpcWebClientChannel.xhr(Uri.parse(proxyUrl));
    _client = TemperatureConverterClient(channel);
  }

  Future<void> _convertToFahrenheit() async {
    final celsius = double.tryParse(_celsiusController.text);
    if (celsius == null) {
      setState(() {
        _fahrenheitResult = 'Invalid input';
        _fahrenheitFormula = '';
      });
      return;
    }

    try {
      final request = TemperatureRequest()..value = celsius;
      final response = await _client.convertToFahrenheit(request);
      
      setState(() {
        _fahrenheitResult = '${response.value.toStringAsFixed(2)} ${response.unit}';
        _fahrenheitFormula = response.formula;
      });
    } catch (e) {
      setState(() {
        _fahrenheitResult = 'Error: $e';
        _fahrenheitFormula = '';
      });
    }
  }

  Future<void> _convertToCelsius() async {
    final fahrenheit = double.tryParse(_fahrenheitController.text);
    if (fahrenheit == null) {
      setState(() {
        _celsiusResult = 'Invalid input';
        _celsiusFormula = '';
      });
      return;
    }

    try {
      final request = TemperatureRequest()..value = fahrenheit;
      final response = await _client.convertToCelsius(request);
      
      setState(() {
        _celsiusResult = '${response.value.toStringAsFixed(2)} ${response.unit}';
        _celsiusFormula = response.formula;
      });
    } catch (e) {
      setState(() {
        _celsiusResult = 'Error: $e';
        _celsiusFormula = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF121212),
              const Color(0xFF1E1E2E),
              const Color(0xFF2A2A3E),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                const SizedBox(height: 20),
                const Icon(Icons.thermostat, size: 64, color: Color(0xFFFF6B35)),
                const SizedBox(height: 16),
                const Text(
                  'Temperature Converter',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'gRPC + Protocol Buffers',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF00D9FF),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Celsius to Fahrenheit
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B35).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.ac_unit, color: Color(0xFF00D9FF)),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Celsius → Fahrenheit',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _celsiusController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Enter Celsius',
                            hintText: '0.0',
                            suffixText: '°C',
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _convertToFahrenheit,
                            child: const Text('Convert to Fahrenheit', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                        if (_fahrenheitResult.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A2A3E),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFF6B35), width: 2),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Result:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _fahrenheitResult,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFF6B35),
                                  ),
                                ),
                                if (_fahrenheitFormula.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    _fahrenheitFormula,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white60,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Fahrenheit to Celsius
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00D9FF).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.wb_sunny, color: Color(0xFFFF6B35)),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Fahrenheit → Celsius',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _fahrenheitController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Enter Fahrenheit',
                            hintText: '32.0',
                            suffixText: '°F',
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _convertToCelsius,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00D9FF),
                            ),
                            child: const Text('Convert to Celsius', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                        if (_celsiusResult.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A2A3E),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF00D9FF), width: 2),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Result:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _celsiusResult,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00D9FF),
                                  ),
                                ),
                                if (_celsiusFormula.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    _celsiusFormula,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white60,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Footer
                const Text(
                  'Built with Flutter • gRPC-Web • Go',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white38,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _celsiusController.dispose();
    _fahrenheitController.dispose();
    super.dispose();
  }
}

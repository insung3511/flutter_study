import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/ollama_config.dart';
import '../services/ollama_service.dart';

class ServerConfigScreen extends StatefulWidget {
  const ServerConfigScreen({super.key});

  @override
  State<ServerConfigScreen> createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends State<ServerConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _customUrlController = TextEditingController();
  
  String _selectedServerType = OllamaConfig.localhost;
  bool _isLoading = false;
  bool _isTestingConnection = false;
  String? _connectionStatus;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  Future<void> _loadCurrentConfig() async {
    final config = await OllamaConfig.getServerConfig();
    setState(() {
      _selectedServerType = config['serverType'];
      _hostController.text = config['host'] ?? '';
      _portController.text = config['port']?.toString() ?? '11434';
      _customUrlController.text = config['customUrl'] ?? '';
    });
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionStatus = null;
    });

    try {
      final ollamaService = OllamaService();
      final isRunning = await ollamaService.isOllamaRunning();
      
      setState(() {
        _connectionStatus = isRunning 
          ? '✅ Connection successful!' 
          : '❌ Connection failed. Make sure Ollama is running on the server.';
      });
    } catch (e) {
      setState(() {
        _connectionStatus = '❌ Connection error: $e';
      });
    } finally {
      setState(() {
        _isTestingConnection = false;
      });
    }
  }

  Future<void> _saveConfiguration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? customUrl;
      
      if (_selectedServerType == OllamaConfig.custom) {
        customUrl = _customUrlController.text.trim();
      } else if (_selectedServerType == OllamaConfig.raspberryPi || 
                 _selectedServerType == OllamaConfig.linuxServer) {
        final host = _hostController.text.trim();
        final port = int.tryParse(_portController.text.trim()) ?? 11434;
        customUrl = OllamaConfig.buildUrl(host, port);
      }

      await OllamaConfig.setServerConfig(
        serverType: _selectedServerType,
        customUrl: customUrl,
        host: _hostController.text.trim().isNotEmpty ? _hostController.text.trim() : null,
        port: int.tryParse(_portController.text.trim()),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuration saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving configuration: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Server Configuration'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Server Type',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedServerType,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: OllamaConfig.localhost,
                            child: const Text('Localhost (Development)'),
                          ),
                          DropdownMenuItem(
                            value: OllamaConfig.raspberryPi,
                            child: const Text('Raspberry Pi'),
                          ),
                          DropdownMenuItem(
                            value: OllamaConfig.linuxServer,
                            child: const Text('Linux Server'),
                          ),
                          DropdownMenuItem(
                            value: OllamaConfig.custom,
                            child: const Text('Custom URL'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedServerType = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              if (_selectedServerType == OllamaConfig.custom) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Custom URL',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _customUrlController,
                          decoration: const InputDecoration(
                            labelText: 'Server URL',
                            hintText: 'http://192.168.1.100:11434',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a server URL';
                            }
                            if (!OllamaConfig.isValidUrl(value.trim())) {
                              return 'Please enter a valid URL';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (_selectedServerType != OllamaConfig.localhost) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Server Details',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _hostController,
                          decoration: InputDecoration(
                            labelText: 'Host/IP Address',
                            hintText: _selectedServerType == OllamaConfig.raspberryPi 
                              ? '192.168.1.100' 
                              : '192.168.1.200',
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a host address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _portController,
                          decoration: const InputDecoration(
                            labelText: 'Port',
                            hintText: '11434',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a port number';
                            }
                            final port = int.tryParse(value.trim());
                            if (port == null || port < 1 || port > 65535) {
                              return 'Please enter a valid port number (1-65535)';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              
              if (_connectionStatus != null) ...[
                Card(
                  color: _connectionStatus!.contains('✅') 
                    ? Colors.green.shade50 
                    : Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _connectionStatus!,
                      style: TextStyle(
                        color: _connectionStatus!.contains('✅') 
                          ? Colors.green.shade800 
                          : Colors.red.shade800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isTestingConnection ? null : _testConnection,
                      icon: _isTestingConnection 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_find),
                      label: Text(_isTestingConnection ? 'Testing...' : 'Test Connection'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveConfiguration,
                      icon: _isLoading 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                      label: Text(_isLoading ? 'Saving...' : 'Save Configuration'),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Setup Instructions',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getSetupInstructions(),
                        style: TextStyle(color: Colors.blue.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSetupInstructions() {
    switch (_selectedServerType) {
      case OllamaConfig.raspberryPi:
        return '''
1. Install Ollama on your Raspberry Pi:
   curl -fsSL https://ollama.ai/install.sh | sh

2. Start Ollama service:
   ollama serve

3. Pull a model (e.g., gemma2:1b):
   ollama pull gemma2:1b

4. Find your Pi's IP address:
   hostname -I

5. Enter the IP address above and test the connection.
        ''';
      case OllamaConfig.linuxServer:
        return '''
1. Install Ollama on your Linux server:
   curl -fsSL https://ollama.ai/install.sh | sh

2. Start Ollama service:
   ollama serve

3. Pull a model (e.g., gemma2:1b):
   ollama pull gemma2:1b

4. Find your server's IP address:
   hostname -I

5. Enter the IP address above and test the connection.
        ''';
      case OllamaConfig.custom:
        return '''
1. Ensure your Ollama server is accessible from this device
2. Make sure the server allows connections on the specified port
3. Check firewall settings if connection fails
4. Test the connection using the button above
        ''';
      default:
        return '''
1. Install Ollama locally:
   curl -fsSL https://ollama.ai/install.sh | sh

2. Start Ollama service:
   ollama serve

3. Pull a model (e.g., gemma2:1b):
   ollama pull gemma2:1b
        ''';
    }
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _customUrlController.dispose();
    super.dispose();
  }
}

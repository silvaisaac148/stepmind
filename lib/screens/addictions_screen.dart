import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AddictionsScreen extends StatelessWidget {
  const AddictionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Información sobre Adicciones'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildAddictionCard(
              context,
              'Adicciones Tecnológicas',
              Icons.computer,
              [
                'Uso excesivo de redes sociales',
                'Gaming disorder',
                'Adicción a smartphones',
                'Nomofobia (miedo a estar sin celular)',
              ],
              Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildAddictionCard(
              context,
              'Adicciones Sustancias',
              Icons.local_drink,
              [
                'Alcoholismo',
                'Tabaquismo',
                'Drogadicción',
                'Cafeinismo',
              ],
              Colors.red,
            ),
            const SizedBox(height: 16),
            _buildAddictionCard(
              context,
              'Adicciones Conductuales',
              Icons.psychology,
              [
                'Ludopatía (juego patológico)',
                'Compras compulsivas',
                'Trastorno de alimentación',
                'Adicción al trabajo',
              ],
              Colors.purple,
            ),
            const SizedBox(height: 16),
            _buildResourcesCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAddictionCard(
    BuildContext context,
    String title,
    IconData icon,
    List<String> items,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3A3634),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      color: Colors.grey[300],
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildResourcesCard(BuildContext context) {
    return FutureBuilder(
      future: _checkInternetConnection(),
      builder: (context, snapshot) {
        final hasInternet = snapshot.data ?? true;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF3A3634),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.support_agent, color: Colors.green),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Recursos de Ayuda',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _launchURL,
                icon: const Icon(Icons.open_in_browser),
                label: Text(hasInternet ? 'Obtener Más Recursos' : 'Obtener Más Recursos (Sin Internet)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasInternet ? Colors.green : Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
              if (!hasInternet)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Necesitas conexión a internet para ver los recursos.',
                    style: TextStyle(color: Colors.grey.shade300),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await Connectivity().checkConnectivity();
      final hasConnection = result.contains(ConnectivityResult.wifi) || 
                           result.contains(ConnectivityResult.mobile) ||
                           result.contains(ConnectivityResult.ethernet);
      return hasConnection;
    } catch (e) {
      return false;
    }
  }

  Future<void> _launchURL() async {
    final url = Uri.parse('https://www.adictalia.es/noticias/tipos-adicciones/');
    
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('No se pudo abrir $url: $e');
    }
  }
}

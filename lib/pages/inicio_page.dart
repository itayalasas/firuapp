import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkIfOnboardingSeen();
  }

  // Check if onboarding has been seen
  Future<void> _checkIfOnboardingSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

    if (seenOnboarding) {
      // If already seen, navigate to login
      _goToLoginScreen();
    }
  }

  // Set onboarding as seen
  Future<void> _setOnboardingSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('seenOnboarding', true);
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _goToNextPage() async {
    if (_currentIndex < 2) {
      _controller.animateToPage(_currentIndex + 1, duration: Duration(milliseconds: 300), curve: Curves.easeIn);
    } else {
      await _setOnboardingSeen();
      _goToLoginScreen();
    }
  }

  void _goToLoginScreen() {
    // Replace this with your navigation to the login screen
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            onPageChanged: _onPageChanged,
            children: [
              _buildPage(
                image: 'lib/assets/pet_owner.jpg',
                title: 'Ventajas para Propietarios',
                description: 'Registra tu mascota y obtén acceso a su historial médico, recordatorios de citas, y mucho más.',
              ),
              _buildPage(
                image: 'lib/assets/business_owner.jpg',
                title: 'Ventajas para Negocios',
                description: 'Registra tu negocio de mascotas, accede a una agenda organizada, gestiona tus clientes y ofrece servicios personalizados.',
              ),
              _buildPage(
                image: 'lib/assets/easy_management.jpg',
                title: 'Gestión Fácil y Eficiente',
                description: 'Disfruta de una experiencia de usuario amigable que te ayuda a organizar y gestionar todo en un solo lugar.',
              ),
            ],
          ),
          // Navigation buttons and indicators
          Positioned(
            bottom: 30.0,
            left: 16.0,
            right: 16.0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [0, 1, 2].map((index) {
                    return GestureDetector(
                      onTap: () => _controller.animateToPage(index, duration: Duration(milliseconds: 300), curve: Curves.easeIn),
                      child: Container(
                        width: 12.0,
                        height: 12.0,
                        margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentIndex == index ? Colors.blueAccent : Colors.grey,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 20.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () async {
                        await _setOnboardingSeen();
                        _goToLoginScreen();
                      },
                      child: Text('Omitir', style: TextStyle(color: Colors.blue)),
                    ),
                    ElevatedButton(
                      onPressed: _goToNextPage,
                      child: Text(_currentIndex == 2 ? 'Empezar' : 'Siguiente'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage({required String image, required String title, required String description}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(image, height: 200.0),
          SizedBox(height: 30.0),
          Text(
            title,
            style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20.0),
          Text(
            description,
            style: TextStyle(fontSize: 16.0, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

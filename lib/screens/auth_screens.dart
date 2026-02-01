import 'package:flutter/material.dart';
import 'package:tiara_fin/screens/admin_screens.dart';
import 'package:tiara_fin/screens/user_screens.dart'; // Tetep butuh ini biar user bisa masuk rumah
import 'package:tiara_fin/services.dart';


// ========== TUKANG GAMBAR EFEK KHUSUS (PAINTER) ==========
class WavyHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 50);
    
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 30);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);
    
    var secondControlPoint = Offset(size.width - (size.width / 4), size.height - 80);
    var secondEndPoint = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy, secondEndPoint.dx, secondEndPoint.dy);
    
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
// =====================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isObscure = true;
  bool _rememberMe = false;
  final _authService = AuthService();
  bool _isLoading = false;

  void _login() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Isi semua data dulu ya!")));
      return;
    }

    setState(() => _isLoading = true);
    final user = await _authService.login(_emailCtrl.text, _passCtrl.text);
    setState(() => _isLoading = false);

    if (user != null) {
      if (!mounted) return;
      // Petunjuk arah sesuai jabatan
      if (user.role == 'admin' || user.role == 'ketua_rt') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminMainScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserMainScreen()));
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email atau password salah nih!")),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Warna dasar alias background
      body: Stack(
        children: [
          // Header Bergelombang Manja
          ClipPath(
            clipper: WavyHeaderClipper(),
            child: Container(
              height: 320,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF009688), Color(0xFF00796B)], // Warna utama aplikasi (dipatenkan)
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/logo.png', height: 100, width: 100, errorBuilder: (c,o,s) => const Icon(Icons.home, size: 80, color: Colors.white)),
                    const SizedBox(height: 16),
                    const Text(
                      "TIARA FIN",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Text(
                      "Sistem Keuangan RT Modern",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 40), // Ruang buat lekukan
                  ],
                ),
              ),
            ),
          ),
          
          // Isinya diamanin dari poni HP dan Keyboard
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Spasi pintar, nyiut kalo keyboard nongol
                    const SizedBox(height: 180), 
                    
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "Selamat Datang!",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Silakan login untuk melanjutkan",
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _emailCtrl,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passCtrl,
                            obscureText: _isObscure,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(_isObscure ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setState(() => _isObscure = !_isObscure),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                activeColor: const Color(0xFF009688),
                                onChanged: (val) => setState(() => _rememberMe = val ?? false),
                              ),
                              const Text('Ingat saya'),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF009688),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 5,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24, 
                                      height: 24, 
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                                    )
                                  : const Text("LOGIN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
                


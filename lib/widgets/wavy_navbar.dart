import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:tiara_fin/theme.dart';

class WavyBottomBar extends StatefulWidget {
  final int selectedIndex;
  final List<IconData> items;
  final Function(int) onItemSelected;

  const WavyBottomBar({
    super.key,
    required this.selectedIndex,
    required this.items,
    required this.onItemSelected,
  });

  @override
  State<WavyBottomBar> createState() => _WavyBottomBarState();
}

class _WavyBottomBarState extends State<WavyBottomBar> {
  @override
  Widget build(BuildContext context) {
    // Lebar dikurangin margin biar pas
    final width = MediaQuery.of(context).size.width - 40; 
    final itemWidth = width / widget.items.length;

    return Container(
      height: 80, // Tinggiin dikit biar keliatan melayang
      width: width,
      margin: const EdgeInsets.only(bottom: 20),
      child: Stack(
        children: [
          // Background Kaca (Glassmorphism)
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8), // Putih transparan biar kece
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  boxShadow: AppTheme.softShadow,
                ),
              ),
            ),
          ),
          
          // Barisan Ikon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: widget.items.asMap().entries.map((entry) {
              final idx = entry.key;
              final icon = entry.value;
              final isActive = idx == widget.selectedIndex;

              return GestureDetector(
                onTap: () => widget.onItemSelected(idx),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                   width: itemWidth,
                   height: 80,
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       // Ikon Goyang
                       AnimatedScale(
                         duration: const Duration(milliseconds: 200),
                         scale: isActive ? 1.2 : 1.0,
                         curve: Curves.easeOutBack,
                         child: Container(
                           padding: const EdgeInsets.all(12),
                           decoration: BoxDecoration(
                             color: isActive ? AppTheme.primary : Colors.transparent,
                             shape: BoxShape.circle,
                             boxShadow: isActive ? AppTheme.glowShadow(AppTheme.primary) : null,
                           ),
                           child: Icon(
                             icon,
                             color: isActive ? Colors.white : AppTheme.textSecondary,
                             size: 24,
                           ),
                         ),
                       ),
                       const SizedBox(height: 4),
                       // Titik Penanda
                       AnimatedContainer(
                         duration: const Duration(milliseconds: 300),
                         width: isActive ? 4 : 0,
                         height: isActive ? 4 : 0,
                         decoration: const BoxDecoration(
                           color: AppTheme.primary,
                           shape: BoxShape.circle,
                         ),
                       )
                     ],
                   ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

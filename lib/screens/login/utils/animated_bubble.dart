import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedBubbleBackground extends StatefulWidget {
  const AnimatedBubbleBackground({super.key});

  @override
  State<AnimatedBubbleBackground> createState() => _AnimatedBubbleBackgroundState();
}

class _AnimatedBubbleBackgroundState extends State<AnimatedBubbleBackground>
    with TickerProviderStateMixin {
  late List<_Bubble> _bubbles;
  final int _numBubbles = 5; // Número de bolhas
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _bubbles = List.generate(_numBubbles, (index) {
      // Duração aleatória para cada bolha, fazendo o movimento parecer mais natural
      final duration = Duration(seconds: _random.nextInt(15) + 15); // Entre 15 e 30 segundos
      final controller = AnimationController(duration: duration, vsync: this)..repeat(reverse: true);
      return _Bubble(
        controller: controller,
        // Posições iniciais e finais aleatórias para o movimento vertical
        startY: _random.nextDouble(),
        endY: _random.nextDouble(),
        startX: _random.nextDouble() * 0.8 + 0.1, // Evitar bordas exatas
        // Tamanho e opacidade aleatórios
        size: _random.nextDouble() * 80 + 60, // Tamanho entre 60 e 140
        opacity: _random.nextDouble() * 0.05 + 0.02, // Opacidade entre 0.02 e 0.07
        // Cor sutil, pode variar se desejar
        color: Colors.white.withOpacity(_random.nextDouble() * 0.03 + 0.01),
      );
    });
  }

  @override
  void dispose() {
    for (var bubble in _bubbles) {
      bubble.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder( // Usar LayoutBuilder para obter as dimensões da tela
      builder: (context, constraints) {
        return Stack(
          children: _bubbles.map((bubble) {
            return AnimatedBuilder(
              animation: bubble.controller,
              builder: (context, child) {
                // Interpola a posição Y
                final currentY = lerpDouble(
                  bubble.startY * constraints.maxHeight, // Posição inicial em pixels
                  bubble.endY * constraints.maxHeight,   // Posição final em pixels
                  bubble.controller.value, // Valor da animação (0.0 a 1.0)
                );
                // Interpola a opacidade (exemplo: de 50% a 100% da opacidade base da bolha)
                final currentOpacity = lerpDouble(bubble.opacity * 0.5, bubble.opacity, sin(bubble.controller.value * pi));


                return Positioned(
                  left: bubble.startX * constraints.maxWidth - (bubble.size / 2),
                  top: currentY! - (bubble.size / 2),
                  child: Opacity(
                    opacity: currentOpacity ?? bubble.opacity,
                    child: Container(
                      width: bubble.size,
                      height: bubble.size,
                      decoration: BoxDecoration(
                        color: bubble.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        );
      }
    );
  }
}

// Classe auxiliar para as propriedades de cada bolha
class _Bubble {
  final AnimationController controller;
  final double startY;
  final double endY;
  final double startX;
  final double size;
  final double opacity;
  final Color color;

  _Bubble({
    required this.controller,
    required this.startY,
    required this.endY,
    required this.startX,
    required this.size,
    required this.opacity,
    required this.color,
  });
}

// Função de interpolação linear (helper)
double? lerpDouble(double? a, double? b, double t) {
  if (a == null || b == null) return null;
  return a + (b - a) * t;
}
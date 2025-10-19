import 'package:flutter/material.dart';

class CustomStepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;

  const CustomStepIndicator({
    Key? key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabels,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps * 2 - 1, (index) {
        if (index.isEven) {
          final stepIndex = index ~/ 2;
          final isActive = stepIndex <= currentStep;
          final isCurrent = stepIndex == currentStep;
          return Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? Colors.blue : Colors.grey,
                  border: Border.all(
                    color:
                        isCurrent ? Colors.blue.shade700 : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${stepIndex + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),
              Text(
                stepLabels[stepIndex],
                style: TextStyle(
                  fontSize: 12,
                  color: isActive ? Colors.black : Colors.grey.shade600,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          );
        } else {
          // line between steps
          final stepIndex = index ~/ 2;
          final isActive = stepIndex < currentStep;
          return Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.only(bottom: 28),
              color: isActive ? Colors.blue : Colors.grey.shade300,
            ),
          );
        }
      }),
    );
  }
}

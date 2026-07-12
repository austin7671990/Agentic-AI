import 'package:flutter/material.dart';

class ToolCallCard extends StatelessWidget {
  final String toolName;
  final Map<String, dynamic> parameters;
  final dynamic result;
  final bool isRunning;

  const ToolCallCard({
    super.key,
    required this.toolName,
    required this.parameters,
    this.result,
    this.isRunning = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool success = result != null && result['success'] == true;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRunning
              ? Colors.amber.withOpacity(0.5)
              : success
                  ? Colors.green.withOpacity(0.3)
                  : Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        leading: isRunning
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                success ? Icons.check_circle : Icons.error,
                color: success ? Colors.greenAccent : Colors.redAccent,
                size: 20,
              ),
        title: Text(
          toolName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          isRunning
              ? 'Running...'
              : success
                  ? 'Completed'
                  : 'Failed',
          style: TextStyle(
            color: isRunning
                ? Colors.amber
                : success
                    ? Colors.greenAccent
                    : Colors.redAccent,
            fontSize: 12,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Parameters:',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    parameters.entries.map((e) => '${e.key}: ${e.value}').join('\n'),
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                if (result != null) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Result:',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      result['data']?.toString() ?? result['error']?.toString() ?? 'No output',
                      style: TextStyle(
                        color: success ? Colors.greenAccent : Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
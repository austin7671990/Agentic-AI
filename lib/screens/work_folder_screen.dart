import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/work_folder_service.dart';
import '../services/sandbox_service.dart';
import '../widgets/file_tree.dart';
import '../widgets/code_viewer.dart';
import '../widgets/sandbox_output.dart';

class WorkFolderScreen extends StatefulWidget {
  const WorkFolderScreen({super.key});

  @override
  State<WorkFolderScreen> createState() => _WorkFolderScreenState();
}

class _WorkFolderScreenState extends State<WorkFolderScreen> {
  final WorkFolderService _workFolder = Get.find<WorkFolderService>();
  final SandboxService _sandbox = Get.find<SandboxService>();
  WorkFile? _selectedFile;
  String _fileContent = '';
  SandboxResult? _lastResult;
  bool _isRunningSandbox = false;

  void _onFileSelected(WorkFile file) async {
    if (file.isDirectory) return;
    final content = await _workFolder.readFile(file.path);
    setState(() {
      _selectedFile = file;
      _fileContent = content;
      _lastResult = null;
    });
  }

  Future<void> _runInSandbox() async {
    if (_selectedFile == null || _fileContent.isEmpty) return;
    setState(() {
      _isRunningSandbox = true;
      _lastResult = null;
    });

    final result = await _sandbox.execute(_fileContent);
    setState(() {
      _lastResult = result;
      _isRunningSandbox = false;
    });
  }

  Future<void> _createNewFile() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New File'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'filename.py'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await _workFolder.createFile(name, '# New file\n');
      await _workFolder.refreshFiles();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Folder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            onPressed: _createNewFile,
            tooltip: 'New File',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _workFolder.refreshFiles();
              setState(() {});
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // File tree (left panel)
          SizedBox(
            width: 160,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.grey.shade900,
                  child: const Row(
                    children: [
                      Icon(Icons.folder_open, size: 16, color: Colors.amber),
                      SizedBox(width: 8),
                      Text('Files', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                Expanded(
                  child: Obx(() => FileTree(
                    files: _workFolder.files.toList(),
                    onFileTap: _onFileSelected,
                    selectedFile: _selectedFile,
                  )),
                ),
              ],
            ),
          ),

          // Code viewer + sandbox (right panel)
          Expanded(
            child: Column(
              children: [
                // Code viewer
                Expanded(
                  flex: 3,
                  child: _selectedFile != null
                      ? CodeViewer(
                          code: _fileContent,
                          filename: _selectedFile!.name,
                        )
                      : const Center(
                          child: Text(
                            'Select a file to view',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                ),

                // Action bar
                if (_selectedFile != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.grey.shade900,
                    child: Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isRunningSandbox ? null : _runInSandbox,
                          icon: _isRunningSandbox
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.play_arrow, size: 18),
                          label: Text(_isRunningSandbox ? 'Running...' : 'Run in Sandbox'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade800,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () async {
                            await _workFolder.deleteFile(_selectedFile!.path);
                            setState(() {
                              _selectedFile = null;
                              _fileContent = '';
                            });
                          },
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Delete'),
                        ),
                      ],
                    ),
                  ),

                // Sandbox output
                Expanded(
                  flex: 2,
                  child: SandboxOutput(
                    result: _lastResult,
                    isRunning: _isRunningSandbox,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
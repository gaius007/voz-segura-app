import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class PhotoStorageService {
  /// Persiste as fotos no diretório seguro, aplica compressão e REMOVE os arquivos temporários.
  Future<List<String>> persistAndCompressPhotos(List<String> tempPaths) async {
    final List<String> savedPaths = [];
    final appDir = await getApplicationDocumentsDirectory();
    final reportsDir = Directory(p.join(appDir.path, 'reports', 'evidence'));
    
    if (!await reportsDir.exists()) {
      await reportsDir.create(recursive: true);
    }

    for (var tempPath in tempPaths) {
      final file = File(tempPath);
      if (!await file.exists()) continue;

      final fileName = 'SEC_${DateTime.now().microsecondsSinceEpoch}.jpg';
      final targetPath = p.join(reportsDir.path, fileName);

      // Compressão para garantir performance e economia de espaço
      final result = await FlutterImageCompress.compressAndGetFile(
        tempPath,
        targetPath,
        quality: 80,
        format: CompressFormat.jpeg,
      );

      if (result != null) {
        savedPaths.add(result.path);
        // REMOVE o arquivo temporário da galeria/câmera após a cópia segura
        try {
          await file.delete();
        } catch (e) {
          // Log ou ignore se o arquivo já tiver sido movido/deletado
        }
      }
    }
    return savedPaths;
  }

  /// Gera um hash SHA-256 do conteúdo COMPRIMIDO + Texto + Timestamp.
  /// Isso garante que se qualquer byte da foto ou metadado for alterado, o hash não baterá.
  Future<String> generateContentHash({
    required String description,
    required List<String> securePhotoPaths,
    required DateTime timestamp,
  }) async {
    final content = StringBuffer();
    
    // 1. Adiciona a descrição
    content.write(description);
    
    // 2. Adiciona o timestamp (em ISO8601 para consistência)
    content.write(timestamp.toIso8601String());
    
    // 3. Adiciona os bytes de cada foto salva e comprimida
    for (var path in securePhotoPaths) {
      final bytes = await File(path).readAsBytes();
      // Usamos o hash dos bytes para compor o hash final
      content.write(sha256.convert(bytes).toString());
    }

    return sha256.convert(utf8.encode(content.toString())).toString();
  }
}

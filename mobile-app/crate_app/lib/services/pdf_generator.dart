import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class PdfGeneratorService {
  /// Generates a PDF invoice based on the provided data and image path
  /// Returns true if PDF was successfully generated and saved, false otherwise
  Future<bool> generateAndSavePdf({
    required String imagePath,
    required List<Map<String, dynamic>> items,
    required BuildContext context,
    required String clientName,
    required String employeeName,
  }) async {
    final pdf = pw.Document();

    // Get current date and time
    final now = DateTime.now();
    final formattedDateTime =
        "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} - ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    // Load the logo image
    final logoBytes = await rootBundle.load(
      'assets/images/logos/Brughera_Drinks.png',
    );
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    // Load the photo image and rotate it before adding to PDF
    final imageBytes = File(imagePath).readAsBytesSync();
    final rotatedImageBytes = await _rotateImage(imageBytes);
    final rotatedImage = pw.MemoryImage(rotatedImageBytes);

    // Define maximum items per page (excluding header and image space)
    const int itemsPerPage = 15; // Adjust based on spacing needs

    // Calculate how many pages we need
    final int totalPages = (items.length / itemsPerPage).ceil();

    // Generate pages
    for (int pageNum = 0; pageNum < totalPages; pageNum++) {
      final startIndex = pageNum * itemsPerPage;
      final endIndex = math.min((pageNum + 1) * itemsPerPage, items.length);
      final pageItems = items.sublist(startIndex, endIndex);
      final isLastPage = pageNum == totalPages - 1;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          header: (pw.Context context) {
            return _buildHeaderComplete(logoImage, formattedDateTime, clientName, employeeName);
          },
          build: (pw.Context context) {
            return [
              if (pageNum == 0) ...[
                pw.SizedBox(height: 10),
                pw.Container(
                  width: double.infinity,
                  height: 250,
                  alignment: pw.Alignment.center,
                  decoration: pw.BoxDecoration(
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(5),
                    ),
                  ),
                  child: pw.ClipRRect(
                    horizontalRadius: 5,
                    verticalRadius: 5,
                    child: pw.Image(rotatedImage, fit: pw.BoxFit.contain),
                  ),
                ),
                pw.SizedBox(height: 15),
              ],

              // Table title for each page
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Dettaglio Casse',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (totalPages > 1)
                      pw.Text(
                        'Pagina ${pageNum + 1} di $totalPages',
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                  ],
                ),
              ),

              // Items table for current page
              _buildItemsTable(pageItems),
              pw.SizedBox(height: 20),

              // Total only on the last page
              if (isLastPage)
                _buildTotal(pageItems),
            ];
          },
        ),
      );
    }

    try {
      final pdfBytes = await pdf.save(); // Save the PDF as bytes

      // Sanitize client name for filename (replace spaces with underscores, remove non-alphanumeric except underscore)
      String sanitizedClientName = clientName
          .replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), '')
          .replaceAll(' ', '_');

      // Use the file picker to choose the save location and pass the bytes directly
      String? filePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Choose where to save the PDF',
        fileName:
            'invoice_${sanitizedClientName}_${now.day.toString().padLeft(2, '0')}_${now.month.toString().padLeft(2, '0')}_${now.year}-${now.hour.toString().padLeft(2, '0')}_${now.minute.toString().padLeft(2, '0')}.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        bytes: pdfBytes, // Pass the required bytes
      );

      if (filePath == null) {
        return false; // User cancelled the save dialog
      }
      return true; // PDF was successfully saved
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error while saving: $e')));
      return false; // Error occurred during PDF creation or saving
    }
  }

  /// Rotates an image 90 degrees clockwise
  Future<Uint8List> _rotateImage(Uint8List imageBytes) async {
    try {
      // Decode the image bytes
      final img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) return imageBytes;

      // Rotate the image 90 degrees clockwise
      final img.Image rotatedImage = img.copyRotate(originalImage, angle: 90);

      // Encode the rotated image back to bytes (PNG format)
      return Uint8List.fromList(img.encodePng(rotatedImage));
    } catch (e) {
      print('Error rotating image: $e');
      // Return original image bytes if rotation fails
      return imageBytes;
    }
  }

  // Complete header with logo, date, and client info
  pw.Widget _buildHeaderComplete(
    pw.MemoryImage logoImage,
    String formattedDateTime,
    String clientName,
    String employeeName,
  ) {
    return pw.Column(
      children: [
        _buildHeader(logoImage, formattedDateTime),
        pw.SizedBox(height: 20),
        _buildClientInfo(clientName, employeeName),
        pw.SizedBox(height: 20),
      ],
    );
  }

  // Header with logo and date
  pw.Widget _buildHeader(pw.MemoryImage logoImage, String formattedDateTime) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Image(logoImage, width: 150, height: 80, fit: pw.BoxFit.contain),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 1),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
          ),
          child: pw.Column(
            children: [
              pw.Text(
                'Fattura',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                formattedDateTime,
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Client and employee info
  pw.Widget _buildClientInfo(String clientName, String employeeName) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Cliente:',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(clientName, style: pw.TextStyle(fontSize: 14)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Dipendente:',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(employeeName, style: pw.TextStyle(fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  // Build items table
  pw.Widget _buildItemsTable(List<Map<String, dynamic>> pageItems) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Table(
        border: pw.TableBorder(
          horizontalInside: pw.BorderSide(color: PdfColors.grey300),
          verticalInside: pw.BorderSide(color: PdfColors.grey300),
        ),
        columnWidths: {
          0: const pw.FlexColumnWidth(2),
          1: const pw.FlexColumnWidth(1.2),
          2: const pw.FlexColumnWidth(1),
          3: const pw.FlexColumnWidth(1),
        },
        children: [
          // Header row
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(5),
                topRight: pw.Radius.circular(5),
              ),
            ),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 10,
                ),
                child: pw.Center(
                  child: pw.Text(
                    'Tipo di bibita',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 10,
                ),
                child: pw.Center(
                  child: pw.Text(
                    'Prezzo unitario',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 10,
                ),
                child: pw.Center(
                  child: pw.Text(
                    'Quantità',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 10,
                ),
                child: pw.Center(
                  child: pw.Text(
                    'Totale',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Data rows
          ...pageItems
              .map(
                (item) => pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 10,
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          item['name'],
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 10,
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          item['price'] != null 
                            ? 'CHF ${item['price'].toStringAsFixed(2)}'
                            : 'N/A',
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 10,
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          item['count'].toString(),
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 10,
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          item['price'] != null 
                            ? 'CHF ${(item['price'] * item['count']).toStringAsFixed(2)}'
                            : 'N/A',
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  // Build total box
  pw.Widget _buildTotal(List<Map<String, dynamic>> items) {
    // Calculate the total price
    double totalPrice = items.fold<double>(
      0,
      (sum, item) {
        if (item['price'] != null) {
          return sum + (item['price'] * item['count']);
        }
        return sum;
      },
    );

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Totale:',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            'CHF ${totalPrice.toStringAsFixed(2)}',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

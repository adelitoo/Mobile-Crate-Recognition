import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;
import 'package:file_picker/file_picker.dart';
import 'package:crate_app/services/pdf_generator.dart';

// Mock classes
class MockFilePicker extends Mock implements FilePickerPlatform {}

class MockPdfDocument extends Mock implements pw.Document {}

class MockImage extends Mock implements img.Image {}

void main() {
  group('PdfGeneratorService Tests', () {
    late PdfGeneratorService pdfService;
    late MockFilePicker mockFilePicker;
    late MockPdfDocument mockPdfDocument;
    late MockImage mockImage;

    setUp(() {
      // Initialize mocks
      mockFilePicker = MockFilePicker();
      mockPdfDocument = MockPdfDocument();
      mockImage = MockImage();

      // Create an instance of your PdfGeneratorService, injecting mocks
      pdfService = PdfGeneratorService(
        filePickerPlatform: mockFilePicker,
        pdfDocument: mockPdfDocument,
        imageService: mockImage,
      );
    });

    test('should generate PDF and save it successfully', () async {
      // Arrange
      const clientName = 'Test Client';
      const items = ['Item 1', 'Item 2', 'Item 3'];
      const pdfPath = '/fake/path/test.pdf';

      // Mock the file picker to return a path
      when(
        mockFilePicker.saveFile(path: anyNamed('path')),
      ).thenAnswer((_) async => pdfPath);

      // Mock the image handling logic (pretend we loaded an image)
      when(mockImage.read(any)).thenReturn(true); // Assuming successful read

      // Act
      await pdfService.generateAndSavePdf(clientName, items);

      // Assert
      verify(mockFilePicker.saveFile(path: anyNamed('path'))).called(1);
      verify(mockPdfDocument.addPage(any)).called(1); // Verify PDF page added
      verify(mockPdfDocument.save()).called(1); // Verify PDF saved
    });

    test('should handle image processing errors gracefully', () async {
      // Arrange
      const clientName = 'Test Client';
      const items = ['Item 1', 'Item 2'];

      // Simulate image loading failure
      when(mockImage.read(any)).thenThrow('Image loading failed');

      // Act
      try {
        await pdfService.generateAndSavePdf(clientName, items);
        fail('Expected exception but none was thrown');
      } catch (e) {
        // Assert
        expect(e, isA<String>());
        expect(e, equals('Image loading failed'));
      }
    });

    test('should handle saving errors gracefully', () async {
      // Arrange
      const clientName = 'Test Client';
      const items = ['Item 1', 'Item 2'];
      const pdfPath = '/fake/path/test.pdf';

      // Mock the file picker to simulate failure in saving
      when(
        mockFilePicker.saveFile(path: anyNamed('path')),
      ).thenThrow('Save failed');

      // Act
      try {
        await pdfService.generateAndSavePdf(clientName, items);
        fail('Expected exception but none was thrown');
      } catch (e) {
        // Assert
        expect(e, isA<String>());
        expect(e, equals('Save failed'));
      }
    });
  });
}

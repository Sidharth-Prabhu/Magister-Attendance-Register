import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'home_screen.dart';

class ReportExportScreen extends StatefulWidget {
  final Classroom classroom;

  ReportExportScreen({required this.classroom});

  @override
  _ReportExportScreenState createState() => _ReportExportScreenState();
}

class _ReportExportScreenState extends State<ReportExportScreen> {
  String _selectedPeriod = 'Daily';
  String _selectedFormat = 'Excel';

  List<String> _getDatesForPeriod(String period) {
    List<String> dates = [];
    DateTime now = DateTime.now();
    DateTime start;

    switch (period) {
      case 'Daily':
        start = DateTime(now.year, now.month, now.day);
        dates.add(start.toIso8601String().split('T')[0]);
        break;
      case 'Weekly':
        start = now.subtract(Duration(days: now.weekday - 1));
        for (int i = 0; i < 7; i++) {
          dates.add(
            start.add(Duration(days: i)).toIso8601String().split('T')[0],
          );
        }
        break;
      case 'Monthly':
        start = DateTime(now.year, now.month, 1);
        int daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        for (int i = 0; i < daysInMonth; i++) {
          dates.add(
            start.add(Duration(days: i)).toIso8601String().split('T')[0],
          );
        }
        break;
      case 'Yearly':
        start = DateTime(now.year, 1, 1);
        for (int i = 0; i < 365; i++) {
          dates.add(
            start.add(Duration(days: i)).toIso8601String().split('T')[0],
          );
        }
        break;
    }
    return dates;
  }

  Future<void> _exportReport() async {
    try {
      List<String> headers = ['Student', 'Roll Number']
        ..addAll(_getDatesForPeriod(_selectedPeriod));
      String className = widget.classroom.name.replaceAll(' ', '_');
      final directory = await getApplicationDocumentsDirectory();

      if (_selectedFormat == 'Excel') {
        var excel = Excel.createExcel();
        Sheet sheet = excel['Attendance'];

        // Set class name header
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
            .value = TextCellValue('Class: ${widget.classroom.name}');
        sheet.merge(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
          CellIndex.indexByColumnRow(
            columnIndex: headers.length - 1,
            rowIndex: 0,
          ),
        );

        // Set column headers
        for (int i = 0; i < headers.length; i++) {
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1))
              .value = TextCellValue(headers[i]);
        }

        // Populate student data
        for (int i = 0; i < widget.classroom.students.length; i++) {
          var student = widget.classroom.students[i];
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 2))
              .value = TextCellValue(student.name);
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 2))
              .value = IntCellValue(student.rollNumber);
          for (int j = 0; j < headers.length - 2; j++) {
            String date = headers[j + 2];
            bool? isPresent = student.attendance[date];
            sheet
                .cell(
                  CellIndex.indexByColumnRow(
                      columnIndex: j + 2, rowIndex: i + 2),
                )
                .value = TextCellValue(
                    isPresent == null ? '-' : isPresent ? 'Present' : 'Absent');
          }
        }

        // Save Excel file
        final path =
            '${directory.path}/${className}_attendance_${_selectedPeriod}.xlsx';
        final file = File(path);
        await file.create(recursive: true);
        final excelData = excel.save();
        if (excelData == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to generate Excel file')),
          );
          return;
        }
        await file.writeAsBytes(excelData);
        final result = await OpenFile.open(path);
        if (result.type != ResultType.done) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to open Excel file: ${result.message}')),
          );
        }
      } else {
        final pdf = pw.Document();
        pdf.addPage(
          pw.Page(
            build: (pw.Context context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Class: ${widget.classroom.name}',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Table.fromTextArray(
                  headers: headers,
                  data: widget.classroom.students.map((student) {
                    List<String> row = [
                      student.name,
                      student.rollNumber.toString(),
                    ];
                    for (String date in headers.skip(2)) {
                      bool? isPresent = student.attendance[date];
                      row.add(
                        isPresent == null
                            ? '-'
                            : isPresent
                                ? 'P'
                                : 'A',
                      );
                    }
                    return row;
                  }).toList(),
                ),
              ],
            ),
          ),
        );

        // Save PDF file
        final pdfPath =
            '${directory.path}/${className}_attendance_${_selectedPeriod}.pdf';
        final pdfFile = File(pdfPath);
        await pdfFile.writeAsBytes(await pdf.save());
        final result = await OpenFile.open(pdfPath);
        if (result.type != ResultType.done) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to open PDF file: ${result.message}')),
          );
        }
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting report: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Export Attendance Report')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Report Period',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              value: _selectedPeriod,
              isExpanded: true,
              items: ['Daily', 'Weekly', 'Monthly', 'Yearly']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPeriod = value!;
                });
              },
            ),
            SizedBox(height: 20),
            Text(
              'Select Format',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              value: _selectedFormat,
              isExpanded: true,
              items: ['Excel', 'PDF']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFormat = value!;
                });
              },
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _exportReport,
                child: Text('Export'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
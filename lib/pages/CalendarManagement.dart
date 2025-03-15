
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';


class CalendarManagementBottomSheet extends StatefulWidget {
  @override
  _CalendarManagementBottomSheetState createState() =>
      _CalendarManagementBottomSheetState();
}

class _CalendarManagementBottomSheetState
    extends State<CalendarManagementBottomSheet> {
  List<bool> _selectedDays = List<bool>.generate(7, (index) => false);
  TimeOfDay _startTime = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = TimeOfDay(hour: 17, minute: 0);
  bool _isSaving = false; // ✅ Controla el estado del guardado

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5, // 50% del tamaño de la pantalla
      minChildSize: 0.3,
      maxChildSize: 0.8,
      builder: (_, controller) {
        return Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                // **Indicador para deslizar**
                Container(
                  padding: EdgeInsets.all(10),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),

                // **Encabezado verde**
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFFA0E3A7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'Configurar Días y Horarios',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    controller: controller,
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        SizedBox(height: 10),

                        // **Selección de días**
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: List.generate(7, (index) {
                            return ChoiceChip(
                              label: Text(_dayLabel(index)),
                              selected: _selectedDays[index],
                              onSelected: (selected) {
                                setState(() {
                                  _selectedDays[index] = selected;
                                });
                              },
                            );
                          }),
                        ),
                        SizedBox(height: 20),

                        // **Seleccionar hora de inicio y fin**
                        _buildTimePickerRow('Hora de inicio', _startTime, true),
                        SizedBox(height: 10),
                        _buildTimePickerRow('Hora de fin', _endTime, false),
                        SizedBox(height: 20),

                        // **Botones de acción**
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center, // ✅ Centrar el botón "Guardar"
                          children: [
                            ElevatedButton(
                              onPressed: _isSaving ? null : _saveWorkSchedule, // ✅ Deshabilita mientras guarda
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green, // Verde menta
                                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12), // ✅ Aumenta el tamaño
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                                  : const Text(
                                'Guardar',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),

                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimePickerRow(String label, TimeOfDay time, bool isStartTime) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text('$label: ${time.format(context)}'),
        ),
        ElevatedButton(
          onPressed: () => _selectTime(context, isStartTime),
          child: Text('Seleccionar'),
        ),
      ],
    );
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _saveWorkSchedule() async {
    setState(() {
      _isSaving = true; // ✅ Activa el loader
    });

    await Future.delayed(Duration(seconds: 2)); // Simulación de guardado

    // Aquí deberías hacer la llamada real a la API
    // Si la respuesta es exitosa, muestra el mensaje de éxito

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      // ✅ Muestra Snackbar de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Calendario guardado exitosamente'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.pop(context); // ✅ Cierra el modal
    }
  }

  String _dayLabel(int index) {
    const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return days[index];
  }
}


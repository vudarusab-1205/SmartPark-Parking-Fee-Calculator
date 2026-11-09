
import 'package:flutter/material.dart';

void main() {
  runApp(const SmartParkApp());
}

// --------------------------------------------------
// APPLICATION CONFIGURATION
// --------------------------------------------------

class SmartParkApp extends StatelessWidget {
  const SmartParkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartPark',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF12A89D),
        ),
        scaffoldBackgroundColor: const Color(0xFFF3F6FA),
        fontFamily: 'Roboto',
      ),
      home: const ParkingHomePage(),
    );
  }
}

// --------------------------------------------------
// VEHICLE TYPES AND TARIFFS
// --------------------------------------------------

enum VehicleType {
  twoWheeler,
  car,
  suv,
}

extension VehicleInfo on VehicleType {
  String get label {
    switch (this) {
      case VehicleType.twoWheeler:
        return 'Two-wheeler';
      case VehicleType.car:
        return 'Car';
      case VehicleType.suv:
        return 'SUV';
    }
  }

  String get emoji {
    switch (this) {
      case VehicleType.twoWheeler:
        return '🏍️';
      case VehicleType.car:
        return '🚗';
      case VehicleType.suv:
        return '🚙';
    }
  }

  double get firstHour {
    switch (this) {
      case VehicleType.twoWheeler:
        return 10;
      case VehicleType.car:
        return 30;
      case VehicleType.suv:
        return 40;
    }
  }

  double get additionalHour {
    switch (this) {
      case VehicleType.twoWheeler:
        return 5;
      case VehicleType.car:
        return 20;
      case VehicleType.suv:
        return 25;
    }
  }

  double get dailyMaximum {
    switch (this) {
      case VehicleType.twoWheeler:
        return 60;
      case VehicleType.car:
        return 200;
      case VehicleType.suv:
        return 250;
    }
  }
}

// --------------------------------------------------
// MAIN PARKING PAGE
// --------------------------------------------------

class ParkingHomePage extends StatefulWidget {
  const ParkingHomePage({super.key});

  @override
  State<ParkingHomePage> createState() =>
      _ParkingHomePageState();
}

class _ParkingHomePageState
    extends State<ParkingHomePage> {

  VehicleType selectedVehicle = VehicleType.car;

  DateTime entryTime =
      DateTime.now().subtract(
    const Duration(hours: 2, minutes: 20),
  );

  DateTime exitTime = DateTime.now();

  bool hasCalculated = false;

  String? errorMessage;

  double parkingFee = 0;

  int parkingMinutes = 0;
  int billableHours = 0;

  bool graceApplied = false;

  // --------------------------------------------------
  // DATE AND TIME FORMATTING
  // --------------------------------------------------

  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String formatTime(DateTime date) {
    final hour = date.hour % 12 == 0
        ? 12
        : date.hour % 12;

    final minute =
        date.minute.toString().padLeft(2, '0');

    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  // --------------------------------------------------
  // DATE AND TIME PICKER
  // --------------------------------------------------

  Future<DateTime?> selectDateTime(
    DateTime initialDate,
  ) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selectedDate == null || !mounted) {
      return null;
    }

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (selectedTime == null) {
      return null;
    }

    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
  }

  Future<void> selectEntryTime() async {
    final result = await selectDateTime(entryTime);

    if (result != null) {
      setState(() {
        entryTime = result;
        hasCalculated = false;
        errorMessage = null;
      });
    }
  }

  Future<void> selectExitTime() async {
    final result = await selectDateTime(exitTime);

    if (result != null) {
      setState(() {
        exitTime = result;
        hasCalculated = false;
        errorMessage = null;
      });
    }
  }

  // --------------------------------------------------
  // PARKING FEE CALCULATION
  // --------------------------------------------------

  void calculateParkingFee() {
    setState(() {
      hasCalculated = false;
      errorMessage = null;

      // Validate entry and exit times

      if (!exitTime.isAfter(entryTime)) {
        errorMessage =
            'Exit time must be later than entry time.';
        return;
      }

      // Calculate parking duration

      parkingMinutes =
          exitTime.difference(entryTime).inMinutes;

      // First 15 minutes are free

      graceApplied = parkingMinutes <= 15;

      if (graceApplied) {
        parkingFee = 0;
        billableHours = 0;
      } else {
        // Remove the free grace period

        int billableMinutes = parkingMinutes - 15;

        // Round partial hours upward

        billableHours =
            (billableMinutes / 60).ceil();

        // Calculate complete 24-hour blocks

        int completeDays = billableHours ~/ 24;

        int remainingHours = billableHours % 24;

        double fullDayCost =
            completeDays * selectedVehicle.dailyMaximum;

        // Calculate remaining hours

        double remainingCost = 0;

        if (remainingHours > 0) {
          remainingCost =
              selectedVehicle.firstHour +
              (remainingHours - 1) *
                  selectedVehicle.additionalHour;
        }

        parkingFee = fullDayCost + remainingCost;

        // Apply daily maximum to the partial day

        double partialDayMaximum =
            selectedVehicle.dailyMaximum;

        if (remainingHours > 0 &&
            parkingFee >
                fullDayCost + partialDayMaximum) {
          parkingFee =
              fullDayCost + partialDayMaximum;
        }
      }

      hasCalculated = true;
    });
  }

  // --------------------------------------------------
  // RESET
  // --------------------------------------------------

  void resetCalculator() {
    setState(() {
      selectedVehicle = VehicleType.car;

      entryTime = DateTime.now().subtract(
        const Duration(hours: 2),
      );

      exitTime = DateTime.now();

      parkingFee = 0;
      parkingMinutes = 0;
      billableHours = 0;

      hasCalculated = false;
      errorMessage = null;
      graceApplied = false;
    });
  }

  // --------------------------------------------------
  // REUSABLE UI COMPONENTS
  // --------------------------------------------------

  Widget sectionTitle(
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF10243A),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.blueGrey,
          ),
        ),
      ],
    );
  }

  Widget vehicleCard(VehicleType vehicle) {
    final isSelected =
        selectedVehicle == vehicle;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            selectedVehicle = vehicle;
            hasCalculated = false;
          });
        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFE5F6F4)
                : const Color(0xFFF7F9FC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF12A89D)
                  : const Color(0xFFE1E8F0),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                vehicle.emoji,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(height: 7),
              Text(
                vehicle.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? const Color(0xFF087F78)
                      : Colors.blueGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget dateTile(
    String label,
    DateTime date,
    VoidCallback onTap,
    IconData icon,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE1E8F0),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF12A89D),
              size: 25,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    formatDate(date),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    formatTime(date),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blueGrey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.edit_calendar_outlined,
              color: Colors.blueGrey,
            ),
          ],
        ),
      ),
    );
  }

  Widget summaryRow(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFB6C5D4),
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // PAYMENT SUMMARY
  // --------------------------------------------------

  Widget paymentSummary() {
    return Card(
      elevation: 0,
      color: const Color(0xFF10243A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'PAYMENT SUMMARY',
              style: TextStyle(
                color: Color(0xFFB6C5D4),
                fontSize: 11,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 22),

            const Text(
              'Total parking fee',
              style: TextStyle(
                color: Color(0xFFB6C5D4),
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              hasCalculated
                  ? '₹${parkingFee.toStringAsFixed(2)}'
                  : '₹ --',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 20),

            const Divider(
              color: Color(0xFF2C4358),
            ),

            summaryRow(
              'Vehicle',
              selectedVehicle.label,
            ),

            summaryRow(
              'Parking duration',
              hasCalculated
                  ? '${parkingMinutes ~/ 60}h ${parkingMinutes % 60}m'
                  : '--',
            ),

            summaryRow(
              'Billable hours',
              hasCalculated
                  ? '$billableHours hours'
                  : '--',
            ),

            summaryRow(
              'Grace period',
              hasCalculated
                  ? (graceApplied
                      ? 'Applied - Free'
                      : 'Not applicable')
                  : '15 minutes',
            ),

            const SizedBox(height: 15),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFF1A354B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                hasCalculated
                    ? (graceApplied
                        ? 'Parking is within the free 15-minute grace period.'
                        : 'Parking fee calculated successfully.')
                    : 'Your parking fee will appear here after calculation.',
                style: const TextStyle(
                  color: Color(0xFFC6D6E4),
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // TARIFF CARD
  // --------------------------------------------------

  Widget tariffCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(
          color: Color(0xFFE8EDF3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            sectionTitle(
              'Parking tariff',
              'Rates based on vehicle type',
            ),

            const SizedBox(height: 15),

            tariffRow(
              'First hour',
              '₹${selectedVehicle.firstHour.toStringAsFixed(0)}',
            ),

            tariffRow(
              'Additional hour',
              '₹${selectedVehicle.additionalHour.toStringAsFixed(0)}',
            ),

            tariffRow(
              'Daily maximum',
              '₹${selectedVehicle.dailyMaximum.toStringAsFixed(0)}',
            ),

            const Divider(height: 22),

            const Text(
              'First 15 minutes are free. Partial hours are rounded up.',
              style: TextStyle(
                fontSize: 11,
                color: Colors.blueGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget tariffRow(
    String label,
    String amount,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.blueGrey,
              ),
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // MAIN UI
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final screenWidth =
        MediaQuery.of(context).size.width;

    final isMobile = screenWidth < 760;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // HEADER

            Container(
              color: const Color(0xFF10243A),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 18 : 45,
                vertical: 18,
              ),
              child: Row(
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: const Color(0xFF12A89D),
                      borderRadius:
                          BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.local_parking_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),

                  const SizedBox(width: 12),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SmartPark',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'PARKING FEE CALCULATOR',
                          style: TextStyle(
                            color: Color(0xFF9FB2C7),
                            fontSize: 9,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons.circle,
                    color: Color(0xFF4DD4A7),
                    size: 9,
                  ),

                  const SizedBox(width: 7),

                  const Text(
                    'Online',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // BODY

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 14 : 45,
                  vertical: 28,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 1050,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Parking Fee Calculator',
                          style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF10243A),
                          ),
                        ),

                        const SizedBox(height: 7),

                        const Text(
                          'Enter your parking details to calculate the total amount payable.',
                          style: TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 13,
                          ),
                        ),

                        const SizedBox(height: 23),

                        // RESPONSIVE LAYOUT

                        if (isMobile)
                          Column(
                            children: [
                              inputCard(),
                              const SizedBox(height: 18),
                              paymentSummary(),
                              const SizedBox(height: 14),
                              tariffCard(),
                            ],
                          )
                        else
                          Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 6,
                                child: inputCard(),
                              ),

                              const SizedBox(width: 18),

                              Expanded(
                                flex: 4,
                                child: Column(
                                  children: [
                                    paymentSummary(),
                                    const SizedBox(height: 14),
                                    tariffCard(),
                                  ],
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 25),

                        const Center(
                          child: Text(
                            '© SmartPark • Parking made simple',
                            style: TextStyle(
                              color: Colors.blueGrey,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // INPUT CARD
  // --------------------------------------------------

  Widget inputCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(
          color: Color(0xFFE8EDF3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            sectionTitle(
              '01  Vehicle information',
              'Choose your vehicle category',
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                vehicleCard(
                  VehicleType.twoWheeler,
                ),
                const SizedBox(width: 9),
                vehicleCard(
                  VehicleType.car,
                ),
                const SizedBox(width: 9),
                vehicleCard(
                  VehicleType.suv,
                ),
              ],
            ),

            const SizedBox(height: 26),

            sectionTitle(
              '02  Parking duration',
              'Select entry and exit date & time',
            ),

            const SizedBox(height: 15),

            dateTile(
              'ENTRY DATE & TIME',
              entryTime,
              selectEntryTime,
              Icons.login_rounded,
            ),

            const SizedBox(height: 12),

            dateTile(
              'EXIT DATE & TIME',
              exitTime,
              selectExitTime,
              Icons.logout_rounded,
            ),

            if (errorMessage != null) ...[
              const SizedBox(height: 13),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEEE),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 23),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: resetCalculator,
                    icon: const Icon(
                      Icons.refresh_rounded,
                    ),
                    label: const Text('Reset'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: calculateParkingFee,
                    icon: const Icon(
                      Icons.calculate_outlined,
                    ),
                    label: const Text(
                      'Calculate fee',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF12A89D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

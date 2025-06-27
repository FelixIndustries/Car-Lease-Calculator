import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lease Deal Checker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
      home: const LeaseCalculatorScreen(),
    );
  }
}

class LeaseCalculatorScreen extends StatefulWidget {
  const LeaseCalculatorScreen({super.key});

  @override
  State<LeaseCalculatorScreen> createState() => _LeaseCalculatorScreenState();
}

class _LeaseCalculatorScreenState extends State<LeaseCalculatorScreen>
    with TickerProviderStateMixin {
  // Input controllers
  final TextEditingController downPaymentController = TextEditingController(text: '3000');
  final TextEditingController monthlyMSRPController = TextEditingController(text: '285');
  final TextEditingController taxesFeesController = TextEditingController(text: '1000');
  final TextEditingController leaseLengthController = TextEditingController(text: '36');
  final TextEditingController salesTaxController = TextEditingController(text: '1.1');
  final TextEditingController carMSRPController = TextEditingController(text: '39500');

  // Calculated values
  double monthlyMSRPZeroDown = 0.0;
  double effectiveMonthlyPayment = 0.0;
  double leaseQualificationRating = 0.0;
  String dealQuality = '';
  Color dealColor = Colors.grey;
  IconData dealIcon = Icons.help;

  // Animation controllers
  late AnimationController _bounceController;
  late AnimationController _slideController;
  late Animation<double> _bounceAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _bounceAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    calculateLease();
    _slideController.forward();
  }

  void calculateLease() {
    try {
      double downPayment = double.parse(downPaymentController.text);
      double monthlyMSRP = double.parse(monthlyMSRPController.text);
      double taxesFees = double.parse(taxesFeesController.text);
      double leaseLength = double.parse(leaseLengthController.text);
      double salesTax = double.parse(salesTaxController.text);
      double carMSRP = double.parse(carMSRPController.text);

      // Formula D3: IF(B2>B1,B2,((B1-B2)/D2)+B2)
      if (monthlyMSRP > downPayment) {
        monthlyMSRPZeroDown = monthlyMSRP;
      } else {
        monthlyMSRPZeroDown = ((downPayment - monthlyMSRP) / leaseLength) + monthlyMSRP;
      }

      // Formula F1: ((D1/D2)+D3)*D4
      effectiveMonthlyPayment = ((taxesFees / leaseLength) + monthlyMSRPZeroDown) * salesTax;

      // Formula F2: F1/D5
      leaseQualificationRating = (effectiveMonthlyPayment / carMSRP) * 100;

      // Determine deal quality
      _evaluateDealQuality();
      
      // Trigger bounce animation when deal changes
      _bounceController.reset();
      _bounceController.forward();

      setState(() {});
    } catch (e) {
      // Handle parsing errors silently
    }
  }

  void _evaluateDealQuality() {
    if (leaseQualificationRating < 0.8) {
      dealQuality = 'NO BRAINER';
      dealColor = const Color(0xFF1B5E20);
      dealIcon = Icons.emoji_events;
    } else if (leaseQualificationRating < 1.0) {
      dealQuality = 'AMAZING';
      dealColor = const Color(0xFF2E7D32);
      dealIcon = Icons.star;
    } else if (leaseQualificationRating < 1.25) {
      dealQuality = 'GREAT';
      dealColor = const Color(0xFF558B2F);
      dealIcon = Icons.thumb_up;
    } else if (leaseQualificationRating <= 1.5) {
      dealQuality = 'GOOD';
      dealColor = const Color(0xFFEF6C00);
      dealIcon = Icons.trending_up;
    } else {
      dealQuality = 'POOR';
      dealColor = const Color(0xFFD32F2F);
      dealIcon = Icons.warning;
    }
  }

  Widget _buildAnimatedInputField(String label, TextEditingController controller, {String prefix = '', int index = 0}) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0, 0.3 + (index * 0.1)),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Interval(index * 0.1, 1.0, curve: Curves.easeOutCubic),
      )),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1565C0),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                prefixText: prefix,
                prefixStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1976D2),
                ),
                hintText: 'Enter value',
                hintStyle: TextStyle(color: Colors.grey[500]),
              ),
              onChanged: (value) {
                HapticFeedback.lightImpact();
                calculateLease();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child, double? height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withAlpha(230),
            Colors.white.withAlpha(180),
          ],
        ),
        border: Border.all(
          color: Colors.white.withAlpha(75),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: child,
        ),
      ),
    );
  }

  Widget _buildResultCard(String title, String value, String subtitle, IconData icon) {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2).withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF1976D2),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1565C0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D47A1),
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBenchmarkRow(String range, String quality, Color color, IconData icon) {
    final bool isCurrentRange = _isInRange(range);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrentRange ? color.withAlpha(38) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentRange ? color : Colors.grey[300]!,
          width: isCurrentRange ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              range,
              style: TextStyle(
                fontWeight: isCurrentRange ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withAlpha(51),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withAlpha(128)),
            ),
            child: Text(
              quality,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isInRange(String range) {
    final rating = leaseQualificationRating;
    switch (range) {
      case 'Below 0.8%':
        return rating < 0.8;
      case '0.8% - 1.0%':
        return rating >= 0.8 && rating < 1.0;
      case '1.0% - 1.25%':
        return rating >= 1.0 && rating < 1.25;
      case '1.25% - 1.5%':
        return rating >= 1.25 && rating <= 1.5;
      case 'Above 1.5%':
        return rating > 1.5;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text(
          'Lease Deal Checker',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Input Section
            SlideTransition(
              position: _slideAnimation,
              child: _buildGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1976D2).withAlpha(25),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.calculate,
                            color: Color(0xFF1976D2),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Lease Details',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D47A1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildAnimatedInputField('Down Payment', downPaymentController, prefix: '\$', index: 0),
                    _buildAnimatedInputField('Monthly MSRP', monthlyMSRPController, prefix: '\$', index: 1),
                    _buildAnimatedInputField('Taxes and Fees', taxesFeesController, prefix: '\$', index: 2),
                    _buildAnimatedInputField('Lease Length (Months)', leaseLengthController, index: 3),
                    _buildAnimatedInputField('Sales Tax Multiplier', salesTaxController, index: 4),
                    _buildAnimatedInputField('Car\'s Total MSRP', carMSRPController, prefix: '\$', index: 5),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Deal Quality Banner with Animation
            ScaleTransition(
              scale: _bounceAnimation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      dealColor,
                      dealColor.withAlpha(204),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: dealColor.withAlpha(102),
                      spreadRadius: 0,
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      dealIcon,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'DEAL QUALITY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dealQuality,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(51),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${leaseQualificationRating.toStringAsFixed(2)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Calculation Results
            Row(
              children: [
                Expanded(
                  child: _buildResultCard(
                    'Effective Monthly Payment',
                    '\$${effectiveMonthlyPayment.toStringAsFixed(2)}',
                    'Your true monthly cost',
                    Icons.payments,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildResultCard(
                    'Monthly MSRP (0 Down)',
                    '\$${monthlyMSRPZeroDown.toStringAsFixed(2)}',
                    'If you put \$0 down',
                    Icons.money_off,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Benchmark Guide
            _buildGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1976D2).withAlpha(25),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.assessment,
                          color: Color(0xFF1976D2),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Lease Quality Benchmarks',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D47A1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildBenchmarkRow('Below 0.8%', 'NO BRAINER', const Color(0xFF1B5E20), Icons.emoji_events),
                  _buildBenchmarkRow('0.8% - 1.0%', 'AMAZING', const Color(0xFF2E7D32), Icons.star),
                  _buildBenchmarkRow('1.0% - 1.25%', 'GREAT', const Color(0xFF558B2F), Icons.thumb_up),
                  _buildBenchmarkRow('1.25% - 1.5%', 'GOOD', const Color(0xFFEF6C00), Icons.trending_up),
                  _buildBenchmarkRow('Above 1.5%', 'POOR', const Color(0xFFD32F2F), Icons.warning),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // How It Works Section
            _buildGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1976D2).withAlpha(25),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.lightbulb_outline,
                          color: Color(0xFF1976D2),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'How It Works',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D47A1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2).withAlpha(13),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF1976D2).withAlpha(25),
                      ),
                    ),
                    child: const Text(
                      '• Monthly MSRP (0 Down): Spreads your down payment across the lease term\n\n'
                      '• Effective Monthly Payment: Includes taxes, fees, and sales tax\n\n'
                      '• Qualification Rating: Monthly payment as % of car\'s total value\n\n'
                      '• Lower percentages = better deals',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: Color(0xFF1565C0),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _slideController.dispose();
    downPaymentController.dispose();
    monthlyMSRPController.dispose();
    taxesFeesController.dispose();
    leaseLengthController.dispose();
    salesTaxController.dispose();
    carMSRPController.dispose();
    super.dispose();
  }
}
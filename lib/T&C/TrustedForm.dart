import 'package:flutter/material.dart';

class TrustedForm extends StatefulWidget {
  const TrustedForm({Key? key}) : super(key: key);

  @override
  State<TrustedForm> createState() => _TrustedFormState();
}

class _TrustedFormState extends State<TrustedForm> {
  String _selectedPlan = '6 Months';

  final List<Map<String, dynamic>> _plans = [
    {
      'name': '3 Months',
      'price': 1999.00,
      'total': 5997.00,
      'benefits': [
        'Access to all premium products',
        'Priority customer support',
        'Monthly product updates',
        'Basic analytics dashboard',
        '5% discount on all purchases'
      ]
    },
    {
      'name': '6 Months',
      'price': 1749.00,
      'total': 10494.00,
      'benefits': [
        'Everything in 3 Months plan',
        'Advanced analytics dashboard',
        'Early access to new products',
        '10% discount on all purchases',
        'Free shipping on all orders'
      ]
    },
    {
      'name': '1 Year',
      'price': 1499.00,
      'total': 17988.00,
      'benefits': [
        'Everything in 6 Months plan',
        'Premium analytics & insights',
        'Dedicated account manager',
        '15% discount on all purchases',
        'Exclusive members-only products'
      ]
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
        title: const Text(
          'TrustedProducts',
          style: TextStyle(
            color: Color(0xFFFFD700),
            fontWeight: FontWeight.w200,
            letterSpacing: 3.0,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Premium Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1A0A5B),
                    Color(0xFF0D0D14),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFFFF8DC), Color(0xFFFFD700)],
                      tileMode: TileMode.mirror,
                    ).createShader(bounds),
                    child: const Text(
                      'ROYAL',
                      style: TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.w100,
                        letterSpacing: 12.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Hello Customer, Welcome to our 2,15,000+ Royal Family',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 18,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Go and claim the rewards you truly deserve!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontStyle: FontStyle.italic,
                      fontSize: 16,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 1,
                        color: const Color(0xFFFFD700).withOpacity(0.5),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.diamond,
                        color: Color(0xFFFFD700),
                        size: 16,
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 40,
                        height: 1,
                        color: const Color(0xFFFFD700).withOpacity(0.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 60),

            // Premium Plan Cards with Benefits
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: _plans.map((plan) {
                  bool isSelected = _selectedPlan == plan['name'];
                  bool isFeatured = plan['name'] == '6 Months';

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPlan = plan['name'];
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.only(bottom: 30),
                      padding: const EdgeInsets.all(35),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF1A0A5B)
                            : const Color(0xFF151522),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFFD700)
                              : Colors.grey.withOpacity(0.15),
                          width: isSelected ? 2.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withOpacity(0.3),
                            blurRadius: 25,
                            spreadRadius: 3,
                          ),
                          BoxShadow(
                            color: const Color(0xFF1A0A5B).withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          )
                        ]
                            : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                plan['name'],
                                style: TextStyle(
                                  color: isSelected
                                      ? const Color(0xFFFFD700)
                                      : Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w200,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              if (isFeatured)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFFD700),
                                        Color(0xFFE6C200),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFFD700).withOpacity(0.4),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      )
                                    ],
                                  ),
                                  child: const Text(
                                    'POPULAR',
                                    style: TextStyle(
                                      color: Color(0xFF1A0A5B),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '₹${plan['price'].toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: isSelected
                                          ? const Color(0xFFFFD700)
                                          : Colors.white.withOpacity(0.95),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                  Text(
                                    'per month',
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white.withOpacity(0.8)
                                          : Colors.white.withOpacity(0.6),
                                      fontSize: 14,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹${plan['total'].toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: isSelected
                                          ? const Color(0xFFFFD700)
                                          : Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w200,
                                    ),
                                  ),
                                  Text(
                                    'total',
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white.withOpacity(0.8)
                                          : Colors.white.withOpacity(0.6),
                                      fontSize: 14,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 30),

                          // Benefits Section
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MEMBERSHIP BENEFITS',
                                style: TextStyle(
                                  color: isSelected
                                      ? const Color(0xFFFFD700)
                                      : Colors.white.withOpacity(0.7),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 15),
                              ...plan['benefits'].map<Widget>((benefit) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(top: 2, right: 12),
                                        child: Icon(
                                          Icons.check_circle,
                                          color: isSelected
                                              ? const Color(0xFFFFD700)
                                              : const Color(0xFF4CAF50),
                                          size: 18,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          benefit,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white.withOpacity(0.9)
                                                : Colors.white.withOpacity(0.8),
                                            fontSize: 15,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),

                          const SizedBox(height: 30),

                          Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? const LinearGradient(
                                colors: [
                                  Color(0xFFFFD700),
                                  Color(0xFFE6C200),
                                ],
                              )
                                  : LinearGradient(
                                colors: [
                                  Colors.grey.withOpacity(0.15),
                                  Colors.grey.withOpacity(0.25),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: isSelected
                                  ? [
                                BoxShadow(
                                  color: const Color(0xFFFFD700).withOpacity(0.4),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                )
                              ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                isSelected ? 'SELECTED' : 'SELECT',
                                style: TextStyle(
                                  color: isSelected
                                      ? const Color(0xFF1A0A5B)
                                      : Colors.white.withOpacity(0.85),
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 60),

            // Premium Continue Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                height: 70,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFD700),
                      Color(0xFFE6C200),
                      Color(0xFFD4AF37),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.5),
                      blurRadius: 25,
                      spreadRadius: 4,
                    ),
                    BoxShadow(
                      color: const Color(0xFF1A0A5B).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 3,
                    )
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(35),
                    onTap: () {
                      _showConfirmationDialog();
                    },
                    child: const Center(
                      child: Text(
                        'ADD TO CART',
                        style: TextStyle(
                          color: Color(0xFF1A0A5B),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  void _showConfirmationDialog() {
    final plan = _plans.firstWhere((plan) => plan['name'] == _selectedPlan);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF151522),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: const BorderSide(color: Color(0xFFFFD700), width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF1A0A5B),
                      Color(0xFF0D0D14),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 3,
                    )
                  ],
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFFFFD700),
                  size: 50,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'You Selected',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 18,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                plan['name'],
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 28,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                '₹${plan['total'].toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Text(
                            'CANCEL',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _showSuccessDialog();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFFD700),
                              Color(0xFFE6C200),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withOpacity(0.4),
                              blurRadius: 15,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'CONFIRM',
                            style: TextStyle(
                              color: Color(0xFF1A0A5B),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF151522),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: const BorderSide(color: Color(0xFFFFD700), width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF1A0A5B),
                      Color(0xFF0D0D14),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 3,
                    )
                  ],
                ),
                child: const Icon(
                  Icons.verified,
                  color: Color(0xFFFFD700),
                  size: 50,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'PAYMENT SUCCESSFUL',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 24,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                'Thank you for joining our Elite Family!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 40),
              InkWell(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFFD700),
                        Color(0xFFE6C200),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'DONE',
                      style: TextStyle(
                        color: Color(0xFF1A0A5B),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
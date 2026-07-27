import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:rosivia/Feature/intro/language/language_provider.dart';
import 'package:rosivia/Feature/intro/language/language_tile.dart';
import 'package:rosivia/Feature/intro/onboarding/presentation/page/onboarding_view.dart';
import 'package:rosivia/core/styles/colors.dart';

class LanguageView extends StatefulWidget {
  const LanguageView({super.key});

  @override
  State<LanguageView> createState() => _LanguageViewState();
}

class _LanguageViewState extends State<LanguageView> {
  String selectedLanguage = "ar";

  @override
  void initState() {
    super.initState();

    final locale = context.read<LanguageProvider>().locale;

    selectedLanguage = locale.languageCode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bordercolor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 60),

              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(45),
                ),
                child: const Icon(
                  Icons.language_rounded,
                  color: AppColors.primary,
                  size: 45,
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "Welcome to ROSIVA",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Choose your preferred language",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.graycolor, fontSize: 16),
              ),

              const SizedBox(height: 45),

              LanguageTile(
                title: "العربية",
                subtitle: "Arabic",
                flag: "🇪🇬",
                isSelected: selectedLanguage == "ar",
                onTap: () {
                  setState(() {
                    selectedLanguage = "ar";
                  });
                },
              ),

              const SizedBox(height: 18),

              LanguageTile(
                title: "English",
                subtitle: "English",
                flag: "🇺🇸",
                isSelected: selectedLanguage == "en",
                onTap: () {
                  setState(() {
                    selectedLanguage = "en";
                  });
                },
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    await context.read<LanguageProvider>().changeLanguage(
                      selectedLanguage,
                    );

                    if (!mounted) return;

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const OnboardingView()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    "Continue",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

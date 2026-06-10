import 'package:flutter/material.dart';
import 'bio_age_calculator.dart';
import 'longevity_calculator.dart';

class LongevityScreen extends StatefulWidget {
  final BioAgeResult result;
  const LongevityScreen({super.key, required this.result});

  @override
  State<LongevityScreen> createState() => _LongevityScreenState();
}

class _LongevityScreenState extends State<LongevityScreen> 
    with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<int> _animAgeWithRec;
  late Animation<int> _animAgeCurrent;
  late Animation<double> _animBar;

  late int expectedWithRec;
  late int expectedCurrent;
  late List<Map<String, dynamic>> _barData;
  
  Map<String, dynamic>? _loyaltyBonus;
  bool _isLoadingBonus = true;

  // ✅ 7 возрастных порогов (вместо 3)
  static const List<int> _targetAges = [70, 75, 80, 85, 90, 95, 100];

  @override
  void initState() {
    super.initState();
    _loadData();
    
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _animBar = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadData() async {
    // Сначала загружаем бонусы
    final bonus = await LongevityCalculator.calculateLoyaltyBonus();
    
    // Применяем бонус к биовозрасту
    final bioAgeReduction = bonus['bioAgeReduction'] as int;
    
    // Пересчитываем ожидаемую продолжительность жизни с учётом бонуса
    expectedWithRec = LongevityCalculator.calculateExpectedLifespan(
      bioAge: widget.result.biologicalAge,
      smokes: false, bmi: 22.0, activity: 'high', sleepHours: 7,
      isOptimized: true,
      bioAgeReduction: bioAgeReduction,
    );
    
    expectedCurrent = LongevityCalculator.calculateExpectedLifespan(
      bioAge: widget.result.biologicalAge,
      smokes: widget.result.smokes,
      bmi: widget.result.bmi,
      activity: widget.result.activity,
      sleepHours: widget.result.sleepHours,
      isOptimized: false,
      bioAgeReduction: bioAgeReduction,
    );

    // Считаем вероятности для всех 7 возрастов
    final List<Map<String, dynamic>> barData = [];
    for (var age in _targetAges) {
      final bonusForAge = (bonus['bonusesByAge'] as Map<int, double>)[age] ?? 0.0;
      
      barData.add({
        'label_val': age,
        'rec': LongevityCalculator.calculateProbability(
          bioAge: widget.result.biologicalAge - bioAgeReduction,
          targetAge: age,
          smokes: false, bmi: 22.0, activity: 'high', sleepHours: 7,
          isOptimized: true, loyaltyBonus: bonusForAge,
        ),
        'cur': LongevityCalculator.calculateProbability(
          bioAge: widget.result.biologicalAge - bioAgeReduction,
          targetAge: age,
          smokes: widget.result.smokes, bmi: widget.result.bmi,
          activity: widget.result.activity, sleepHours: widget.result.sleepHours,
          isOptimized: false, loyaltyBonus: bonusForAge,
        ),
        'bonus': bonusForAge,
      });
    }

    _animAgeWithRec = IntTween(begin: 0, end: expectedWithRec).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.8, curve: Curves.easeOut)),
    );
    _animAgeCurrent = IntTween(begin: 0, end: expectedCurrent).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 1.0, curve: Curves.easeOut)),
    );

    if (mounted) {
      setState(() {
        _barData = barData;
        _loyaltyBonus = bonus;
        _isLoadingBonus = false;
      });
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Прогноз долголетия'),
        backgroundColor: const Color(0xFF0F1115),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: const Color(0xFF0F1115),
      body: _isLoadingBonus
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00D4AA)))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    'Ваш персональный прогноз',
                    style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Биовозраст: ${widget.result.biologicalAge} лет',
                    style: const TextStyle(color: Color(0xFF00D4AA), fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 30),

                  // Ожидаемая продолжительность жизни
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [const Color(0xFF00D4AA).withValues(alpha: 0.1), Colors.grey[900]!],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF00D4AA).withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.favorite, color: Color(0xFF00D4AA), size: 32),
                        const SizedBox(height: 12),
                        const Text(
                          'Ожидаемая продолжительность жизни',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        _buildAgeStat(animation: _animAgeWithRec, label: 'с выполнением рекомендаций', color: const Color(0xFF00D4AA), isMain: true),
                        const SizedBox(height: 16),
                        const Divider(color: Colors.grey, height: 1),
                        const SizedBox(height: 16),
                        _buildAgeStat(animation: _animAgeCurrent, label: 'при текущем образе жизни', color: Colors.orange, isMain: false),
                        
                        if (expectedWithRec > expectedCurrent) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00D4AA).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.arrow_upward, color: Color(0xFF00D4AA), size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  "+${expectedWithRec - expectedCurrent} лет потенциала",
                                  style: const TextStyle(
                                    color: Color(0xFF00D4AA),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // ✅ Блок бонусов лояльности
                  const SizedBox(height: 24),
                  _buildLoyaltyBonusBlock(),
                  
                  const SizedBox(height: 32),
                  const Align(
                    alignment: Alignment.centerLeft, 
                    child: Text('Вероятность дожить до...', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 20),
                  
                  // 7 прогресс-баров для каждого возраста
                  ..._barData.map((data) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildBarSection('${data['label_val']} лет', data),
                  )),
                  
                  const SizedBox(height: 24),
                  
                  // Пояснение про прогрессивную шкалу
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.trending_up, color: Color(0xFFFFD700), size: 20),
                          SizedBox(width: 10),
                          Text('Прогрессивная шкала бонусов', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ]),
                        SizedBox(height: 8),
                        Text(
                          '💡 Чем выше целевой возраст — тем ценнее ваша дисциплина. '
                         'За каждые 14 дней выполнения заданий вы можете получить рассчитанный AI бонус '
                          'к вероятности дожить до 70, 80, 90 и 100 лет.',
                          style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.grey[850], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[700]!)),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [Icon(Icons.info_outline, color: Color(0xFF00D4AA), size: 24), SizedBox(width: 12), Text('Почему такая разница?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))]),
                        SizedBox(height: 12),
                        Text('Эпидемиологические исследования показывают, что совокупность вредных привычек (курение, лишний вес, низкая активность) может сократить жизнь на 10–12 лет.', style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5)),
                        SizedBox(height: 12),
                        Text('Зелёный прогноз показывает, как изменится ситуация, если устранить эти факторы. Это реальный, достижимый потенциал.', style: TextStyle(color: Colors.white54, fontSize: 15, height: 1.4, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      label: const Text('Вернуться к результатам', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D4AA), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildLoyaltyBonusBlock() {
    if (_loyaltyBonus == null) return const SizedBox.shrink();

    final totalDays = _loyaltyBonus!['totalDaysTracked'] as int;
    final maxStreak = _loyaltyBonus!['maxStreak'] as int;
    final highDisciplineDays = _loyaltyBonus!['highDisciplineDays'] as int;
    final daysToNext = _loyaltyBonus!['daysToNextBonus'] as int;
    final bioAgeReduction = _loyaltyBonus!['bioAgeReduction'] as int;
    final streakBonus = _loyaltyBonus!['streakBonus'] as int;
    final diversityBonus = _loyaltyBonus!['diversityBonus'] as int;
    final improvementBonus = _loyaltyBonus!['improvementBonus'] as int;
    final completedCategories = _loyaltyBonus!['completedCategories'] as int;

    if (totalDays == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Column(
          children: [
            Icon(Icons.emoji_events, color: Colors.grey[600], size: 32),
            const SizedBox(height: 8),
            Text(
              'Начните выполнять задания в трекере,\nчтобы получить бонусы к долголетию',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFD700).withValues(alpha: 0.1),
            Colors.grey[900]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 24),
              SizedBox(width: 8),
              Text(
                'Ваши бонусы лояльности',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Основные метрики
          Row(
            children: [
              Expanded(child: _buildStatCard(
                icon: Icons.calendar_today,
                value: '$totalDays',
                label: 'дней в трекере',
                color: const Color(0xFF00D4AA),
              )),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard(
                icon: Icons.local_fire_department,
                value: '$maxStreak',
                label: 'дней серия',
                color: Colors.orange,
              )),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard(
                icon: Icons.check_circle,
                value: '$highDisciplineDays',
                label: 'дней ≥80%',
                color: Colors.purple,
              )),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // ✅ Бонус к биовозрасту
          if (bioAgeReduction > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00D4AA).withValues(alpha: 0.2),
                    const Color(0xFF00D4AA).withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00D4AA), width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.trending_down, color: Color(0xFF00D4AA), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Бонус к биовозрасту',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          '-$bioAgeReduction ${_getYearWord(bioAgeReduction)}',
                          style: const TextStyle(
                            color: Color(0xFF00D4AA),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _getBioAgeReductionReason(highDisciplineDays),
                          style: TextStyle(color: Colors.grey[400], fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          if (bioAgeReduction > 0) const SizedBox(height: 12),
          
          // Составляющие бонусов
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Составляющие бонусов:',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                const SizedBox(height: 8),
                _buildBonusComponentRow('🔥 За серию дней', '+$streakBonus%'),
                _buildBonusComponentRow('🎨 За разнообразие ($completedCategories/6 категорий)', '+$diversityBonus%'),
                _buildBonusComponentRow('📉 За улучшение биовозраста', '+$improvementBonus%'),
              ],
            ),
          ),
          
          if (daysToNext > 0 && daysToNext <= 14) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF00D4AA).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer, color: const Color(0xFF00D4AA), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Следующий бонус через $daysToNext ${_getDaysWord(daysToNext)}',
                      style: const TextStyle(color: Color(0xFF00D4AA), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getBioAgeReductionReason(int days) {
    if (days >= 180) return '6+ месяцев дисциплины (максимум)';
    if (days >= 120) return '4+ месяца дисциплины';
    if (days >= 60) return '2+ месяца дисциплины';
    return '';
  }

  String _getYearWord(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'год';
    if ([2, 3, 4].contains(n % 10) && ![12, 13, 14].contains(n % 100)) return 'года';
    return 'лет';
  }

  String _getDaysWord(int days) {
    if (days % 10 == 1 && days % 100 != 11) return 'день';
    if ([2, 3, 4].contains(days % 10) && ![12, 13, 14].contains(days % 100)) return 'дня';
    return 'дней';
  }

  Widget _buildBonusComponentRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[300], fontSize: 12),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: TextStyle(color: Colors.grey[400], fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAgeStat({required Animation<int> animation, required String label, required Color color, bool isMain = false}) {
    return AnimatedBuilder(animation: animation, builder: (ctx, _) {
      return Column(children: [
        Text('${animation.value} лет', style: TextStyle(color: color, fontSize: isMain ? 44 : 36, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey[400]!, fontSize: isMain ? 16 : 14)),
      ]);
    });
  }

  Widget _buildBarSection(String label, Map<String, dynamic> data) {
    final bonus = data['bonus'] as double;
    
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
          if (bonus > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '+${bonus.toStringAsFixed(1)}% бонус',
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 8),
      AnimatedBuilder(animation: _animBar, builder: (ctx, _) {
        final fraction = (data['rec'] as int) / 100.0 * _animBar.value;
        return _buildProgressBar(fraction, 'с рекомендациями', const Color(0xFF00D4AA));
      }),
      const SizedBox(height: 6),
      AnimatedBuilder(animation: _animBar, builder: (ctx, _) {
        final fraction = (data['cur'] as int) / 100.0 * _animBar.value;
        return _buildProgressBar(fraction, 'текущий образ жизни', Colors.orange, isSecondary: true);
      }),
    ]);
  }

  Widget _buildProgressBar(double widthFraction, String label, Color color, {bool isSecondary = false}) {
    return Row(children: [
      Expanded(
        child: SizedBox(
          height: 14,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(color: Colors.grey[800]),
              AnimatedContainer(
                duration: const Duration(milliseconds: 50),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: widthFraction.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isSecondary ? 0.8 : 1.0),
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(width: 12),
      SizedBox(width: 80, child: Text('${(widthFraction * 100).round()}%', textAlign: TextAlign.end, style: TextStyle(color: isSecondary ? Colors.grey : Colors.white, fontSize: 15, fontWeight: FontWeight.bold))),
    ]);
  }
}
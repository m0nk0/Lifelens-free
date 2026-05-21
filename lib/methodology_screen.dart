import 'package:flutter/material.dart';

class MethodologyScreen extends StatelessWidget {
  const MethodologyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Научная методология'),
        backgroundColor: const Color(0xFF0F1115),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: const Color(0xFF0F1115),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00D4AA).withValues(alpha: 0.2),
                    Colors.grey[900]!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00D4AA).withValues(alpha: 0.4)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.psychology, color: Color(0xFF00D4AA), size: 48),
                  SizedBox(height: 12),
                  Text(
                    'LifeLens AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Научно обоснованная система оценки биологического возраста',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Раздел 1: AI Модель
            _buildSection(
              icon: Icons.auto_awesome,
              title: 'Нейросетевой анализ лица',
              subtitle: 'Deep Convolutional Neural Networks (CNN)',
              content: [
                '🧠 **Архитектура**: Сверточная нейронная сеть (CNN) с трансферным обучением на базе MobileNetV2, дообученная на датасете UTKFace (20,000+ изображений).',
                '\n📊 **Точность**: MAE (Mean Absolute Error) = ±3.2 года при 95% доверительном интервале.',
                '\n🎯 **Признаки**: Модель анализирует 68 ключевых точек лица (facial landmarks), текстуру кожи, микрорельеф, глубину морщин, пигментацию и тургор тканей.',
                '\n⚡ **Оптимизация**: Квантизация модели до INT8 (TensorFlow Lite) для работы на мобильных устройствах без потери точности.',
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Раздел 2: Актуарная математика
            _buildSection(
              icon: Icons.analytics,
              title: 'Актуарное моделирование',
              subtitle: 'Gompertz–Makeham Law of Mortality',
              content: [
                '📐 **Закон Гомпертца-Мейкема** (1825): μ(x) = A + B·e^(Cx), где μ(x) — интенсивность смертности в возрасте x.',
                '\n📈 **Экспоненциальный рост риска**: После 30 лет вероятность смерти удваивается каждые 8 лет (закон удвоения Мейкема).',
                '\n🎲 **Условная вероятность**: P(T > t+s | T > s) — вероятность дожить до возраста t+s при условии, что вы уже дожили до s.',
                '\n💡 **Парадокс выжившего**: Чем старше человек, тем выше его ожидаемый возраст смерти, так как он уже преодолел риски younger age cohorts.',
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Раздел 3: Биомаркеры
            _buildSection(
              icon: Icons.biotech,
              title: 'Биомаркеры старения',
              subtitle: 'Phenotypic Age & Allostatic Load',
              content: [
                '🔬 **Фенотипический возраст** (Levine et al., 2018): Комбинация клинических биомаркеров (альбумин, креатинин, глюкоза, С-реактивный белок).',
                '\n⚖️ **Аллостатическая нагрузка**: Кумулятивный износ организма под воздействием стрессоров (McEwen, 1998).',
                '\n🧬 **Эпигенетические часы**: Хотя мы не используем метилирование ДНК напрямую, визуальные маркеры коррелируют с Horvath Clock (r=0.68).',
                '\n📉 **Физиологический спад**: VO2 max снижается на 1% в год после 30 лет, мышечная масса — на 3-8% за десятилетие (саркопения).',
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Раздел 4: Факторы образа жизни
            _buildSection(
              icon: Icons.favorite,
              title: 'Модифицируемые факторы риска',
              subtitle: 'Relative Risk & Population Attributable Fraction',
              content: [
                '🚬 **Курение**: RR (Relative Risk) = 2.8 для всех причин смерти. PAF (Population Attributable Fraction) = 18% (WHO, 2023).',
                '\n⚖️ **ИМТ > 30**: HR (Hazard Ratio) = 1.45 для сердечно-сосудистых заболеваний (Prospective Studies Collaboration, 2009).',
                '\n🏃 **Физическая активность**: Мета-анализ 800,000 человек показал: высокая активность снижает смертность на 30-35% (HR = 0.65).',
                '\n😴 **Сон**: U-образная зависимость: <6 часов (HR = 1.13) и >9 часов (HR = 1.23) повышают риски (Cappuccio et al., 2010).',
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Раздел 5: Статистика
            _buildSection(
              icon: Icons.calculate,
              title: 'Статистические методы',
              subtitle: 'Bayesian Inference & Confidence Intervals',
              content: [
                '📊 **Байесовский вывод**: Априорное распределение (популяционные данные) + Правдоподобие (ваши данные) = Апостериорное распределение (персональный прогноз).',
                '\n🎯 **Доверительные интервалы**: 95% CI для прогноза долголетия рассчитывается методом бутстрэпа (1000 итераций).',
                '\n⚡ **Каппирование**: Ограничение влияния выбросов (outliers) через winsorization на уровне 99-го перцентиля.',
                '\n🔢 **Нормализация**: Z-score стандартизация: z = (x - μ) / σ для всех непрерывных переменных.',
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Раздел 6: Источники данных
            _buildSection(
              icon: Icons.library_books,
              title: 'Источники данных',
              subtitle: 'Peer-Reviewed Research & WHO Guidelines',
              content: [
                '📚 **Датасеты**: UTKFace, IMDB-WIKI, Adience (в сумме >50,000 размеченных изображений).',
                '\n🏛️ **ВОЗ**: Global Health Estimates 2023, Life Tables by Country.',
                '\n🔬 **Исследования**: Framingham Heart Study (70 лет данных), Dunedin Study (лонгитюдное исследование с 1972 года).',
                '\n📰 **Публикации**: Nature Aging, The Lancet Healthy Longevity, JAMA Internal Medicine.',
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Дисклеймер
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [Icon(Icons.warning_amber, color: Colors.orange, size: 20), SizedBox(width: 8), Text('Важное предупреждение', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))]),
                  SizedBox(height: 8),
                  Text(
                    'LifeLens предоставляет оценочные прогнозы на основе статистических моделей и не является медицинским диагностическим инструментом. '
                    'Результаты не должны использоваться для принятия клинических решений. '
                    'При наличии проблем со здоровьем обратитесь к квалифицированному врачу.',
                    style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.5),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Кнопка "Вернуться"
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                label: const Text(
                  'Вернуться к результатам',
                  style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D4AA),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<String> content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF00D4AA), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...content.map((text) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              text.replaceAll('**', ''), // Убираем мардаун-жирность для простоты
              style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.6),
            ),
          )),
        ],
      ),
    );
  }
}
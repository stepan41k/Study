using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;

using System.Windows;
using System.Windows.Media;

namespace MP3
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        // Опишите дополнительные поля для организации смены цвета
        private bool isColorChanged = false;
        private Brush initialWindowBackground;

        public MainWindow()
        {
            InitializeComponent();

            // В конструкторе опишите программно обработчик события щелчка по кнопке Btn1,
            // а также, в переменной color запомните начальный цвет фона окна.
            Btn1.Click += Btn1_Click;
            initialWindowBackground = this.Background; // Сохраняем начальный фон окна
        }

        // Добавьте метод для изменения цвета фона окна
        private void Btn1_Click(object sender, RoutedEventArgs e)
        {
            ChangeWindowBackgroundColor();
        }

        private void ChangeWindowBackgroundColor()
        {
            if (isColorChanged)
            {
                this.Background = initialWindowBackground; // Возвращаем исходный цвет
            }
            else
            {
                this.Background = new SolidColorBrush(Colors.LightGreen); // Меняем на новый цвет
            }
            isColorChanged = !isColorChanged; // Инвертируем состояние
        }

        private void BtnClose_Click(object sender, RoutedEventArgs e)
        {  
            this.Close(); // Закрывает текущее окно         
        }
    }
}

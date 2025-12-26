using System.Windows;
using MP6_2.Pages; // Добавьте это пространство имен

namespace MP6_2 // Замените WpfAppExample на имя вашего проекта
{
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();
            // Устанавливаем стартовую страницу
            MainFrame.Navigate(new Authorization());
        }
    }
}
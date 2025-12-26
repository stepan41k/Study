using System.Linq;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;

namespace WpfApp_MenuToolbarStatusBar
{
    public partial class MainWindow : Window
    {
        private Brush _originalGridBackground;
        private int _colorIndex = 0;
        private readonly SolidColorBrush[] _colors = new SolidColorBrush[]
        {
            Brushes.LightCoral, Brushes.LightGreen, Brushes.LightBlue, Brushes.LightYellow, Brushes.Orange, Brushes.Lavender
        };

        public MainWindow()
        {
            InitializeComponent();

            _originalGridBackground = MainContentGrid.Background;

            ChangeColorMenuItem.MouseEnter += MenuItem_MouseEnter;
            AboutMenuItem.MouseEnter += MenuItem_MouseEnter;
            ExitMenuItem.MouseEnter += MenuItem_MouseEnter;
            ChangeColorMenuItem.MouseLeave += Element_MouseLeave;
            AboutMenuItem.MouseLeave += Element_MouseLeave;
            ExitMenuItem.MouseLeave += Element_MouseLeave;

            ChangeColorToolBarButton.MouseEnter += ToolBarButton_MouseEnter;
            AboutToolBarButton.MouseEnter += ToolBarButton_MouseEnter;
            ExitToolBarButton.MouseEnter += ToolBarButton_MouseEnter;
            ChangeColorToolBarButton.MouseLeave += Element_MouseLeave;
            AboutToolBarButton.MouseLeave += Element_MouseLeave;
            ExitToolBarButton.MouseLeave += Element_MouseLeave;
        }

        private void ChangeBackgroundColor_Click(object sender, RoutedEventArgs e)
        {
            MainContentGrid.Background = _colors[_colorIndex];
            _colorIndex = (_colorIndex + 1) % _colors.Length;
        }

        private void About_Click(object sender, RoutedEventArgs e)
        {
            MessageBox.Show("Разработчик: Raspopov Stepan\nВерсия: 1.0\nГод: 2025", "О программе", MessageBoxButton.OK, MessageBoxImage.Information);
        }

        private void Exit_Click(object sender, RoutedEventArgs e)
        {
            this.Close();
        }

        private void MenuItem_MouseEnter(object sender, MouseEventArgs e)
        {
            if (sender is MenuItem menuItem)
            {
                string headerText = menuItem.Header.ToString().Replace("_", "");
                StatusBarText.Text = $"Действие: {headerText}";
            }
        }

        private void ToolBarButton_MouseEnter(object sender, MouseEventArgs e)
        {
            if (sender is Button button && button.ToolTip != null)
            {
                StatusBarText.Text = $"Действие: {button.ToolTip}";
            }
        }

        private void Element_MouseLeave(object sender, MouseEventArgs e)
        {
            StatusBarText.Text = "Готово";
        }

        private void FileMenu_Click(object sender, RoutedEventArgs e)
        {

        }
    }
}
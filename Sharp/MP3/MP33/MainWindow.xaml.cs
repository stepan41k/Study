using System.Collections.Generic;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;

namespace WpfApp_LayoutDynamic
{
    // Вспомогательный класс для определения свойств блока
    public class BlockDefinition
    {
        public Brush Color { get; set; }
        public string Content { get; set; }
    }

    public partial class MainWindow : Window
    {
        // Словарь для хранения определений блоков по имени файла
        private readonly Dictionary<string, BlockDefinition> _blockDefinitions = new Dictionary<string, BlockDefinition>
        {
            { "1.txt", new BlockDefinition { Color = Brushes.Yellow, Content = "A" } },
            { "2.txt", new BlockDefinition { Color = Brushes.Red, Content = "B" } },
            { "3.txt", new BlockDefinition { Color = Brushes.Green, Content = "C" } },
            { "4.txt", new BlockDefinition { Color = Brushes.Blue, Content = "D" } },
            { "5.txt", new BlockDefinition { Color = Brushes.Gray, Content = "E" } },
            { "6.txt", new BlockDefinition { Color = Brushes.LightYellow, Content = "F" } }
        };

        public MainWindow()
        {
            InitializeComponent();
        }

        // Обработчик для кнопок в верхней панели (функционал из предыдущего задания)
        private void TopCommandButton_Click(object sender, RoutedEventArgs e)
        {
            if (sender is Button button)
            {
                MessageBox.Show($"Нажата кнопка: {button.Content}", "Действие", MessageBoxButton.OK, MessageBoxImage.Information);
            }
        }

        // Обработчик для ссылок "Последние документы" (функционал из предыдущего задания)
        private void RecentDocument_MouseLeftButtonDown(object sender, MouseButtonEventArgs e)
        {
            if (sender is TextBlock textBlock)
            {
                MessageBox.Show($"Открыт документ: {textBlock.Text}", "Последние документы", MessageBoxButton.OK, MessageBoxImage.Information);
            }
        }

        // Обработчик для TextBlock'ов в левом списке файлов - добавляет блок
        private void FileListTextBlock_MouseLeftButtonDown(object sender, MouseButtonEventArgs e)
        {
            if (sender is TextBlock textBlock)
            {
                string fileName = textBlock.Text;
                if (_blockDefinitions.TryGetValue(fileName, out BlockDefinition blockDef))
                {
                    // Создаем новый элемент Border
                    Border newBlock = CreateBlockElement(blockDef.Color, blockDef.Content);
                    // Добавляем его в WrapPanel
                    ColorBlocksWrapPanel.Children.Add(newBlock);
                }
            }
        }

        // Обработчик для динамически созданных цветных блоков - удаляет блок
        private void DynamicColorBlock_MouseLeftButtonDown(object sender, MouseButtonEventArgs e)
        {
            if (sender is Border borderToRemove)
            {
                // Удаляем нажатый блок из WrapPanel
                ColorBlocksWrapPanel.Children.Remove(borderToRemove);
            }
        }

        // Вспомогательный метод для создания элемента Border с TextBlock внутри
        private Border CreateBlockElement(Brush color, string content)
        {
            Border border = new Border
            {
                Background = color,
                Width = 80,
                Height = 80,
                Margin = new Thickness(5),
                CornerRadius = new CornerRadius(5),
                // Можно добавить Tag для идентификации, если потребуется сложный функционал
                Tag = content
            };

            TextBlock textBlock = new TextBlock
            {
                Text = content,
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment = VerticalAlignment.Center,
                FontSize = 20,
                FontWeight = FontWeights.Bold,
                // Автоматически выбираем цвет текста для лучшей читаемости
                Foreground = (color == Brushes.Yellow || color == Brushes.LightYellow) ? Brushes.Black : Brushes.White
            };

            border.Child = textBlock;
            // Прикрепляем обработчик для удаления блока при клике
            border.MouseLeftButtonDown += DynamicColorBlock_MouseLeftButtonDown;

            return border;
        }
    }
}
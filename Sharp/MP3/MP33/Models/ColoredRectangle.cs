using System.ComponentModel;
using System.Windows.Media;

namespace MP33.Models
{
    public class ColoredRectangle : INotifyPropertyChanged
    {
        private string _letter;
        public string Letter
        {
            get { return _letter; }
            set
            {
                if (_letter != value)
                {
                    _letter = value;
                    OnPropertyChanged(nameof(Letter));
                }
            }
        }

        private SolidColorBrush _backgroundColor;
        public SolidColorBrush BackgroundColor
        {
            get { return _backgroundColor; }
            set
            {
                if (_backgroundColor != value)
                {
                    _backgroundColor = value;
                    OnPropertyChanged(nameof(BackgroundColor));
                }
            }
        }

        private bool _isVisible;
        public bool IsVisible
        {
            get { return _isVisible; }
            set
            {
                if (_isVisible != value)
                {
                    _isVisible = value;
                    OnPropertyChanged(nameof(IsVisible));
                }
            }
        }

        private int _correspondingDocumentIndex;
        public int CorrespondingDocumentIndex
        {
            get { return _correspondingDocumentIndex; }
            set
            {
                if (_correspondingDocumentIndex != value)
                {
                    _correspondingDocumentIndex = value;
                    OnPropertyChanged(nameof(CorrespondingDocumentIndex));
                }
            }
        }

        public event PropertyChangedEventHandler PropertyChanged;

        protected virtual void OnPropertyChanged(string propertyName)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }
}
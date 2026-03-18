package unischedule.ui;

import java.awt.BorderLayout;
import java.awt.Dimension;
import java.awt.FlowLayout;
import java.awt.Font;

import javax.swing.JButton;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JTable;
import javax.swing.ListSelectionModel;
import javax.swing.border.EmptyBorder;

import unischedule.logic.ScheduleManager;
import unischedule.ui.components.ScheduleTableModel;

/**
 * Главное окно приложения UniSchedule.
 * Отвечает за визуализацию расписания и навигацию пользователя.
 */
public class MainFrame extends JFrame {
    private final ScheduleManager manager;
    private final JTable scheduleTable;
    private final ScheduleTableModel tableModel;

    public MainFrame(ScheduleManager manager) {
        this.manager = manager;
        
        // Настройки окна
        setTitle("UniSchedule — Система управления расписанием");
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setSize(1000, 600);
        setMinimumSize(new Dimension(800, 400));
        setLocationRelativeTo(null); // Центрирование на экране

        // Инициализация модели таблицы (MVC подход)
        this.tableModel = new ScheduleTableModel(manager.getLessons());
        this.scheduleTable = new JTable(tableModel);
        
        // Настройка внешнего вида таблицы
        setupTableAppearance();

        // Сборка интерфейса
        initLayout();
    }

    private void setupTableAppearance() {
        scheduleTable.setRowHeight(30);
        scheduleTable.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        scheduleTable.getTableHeader().setReorderingAllowed(false);
        scheduleTable.setFont(new Font("SansSerif", Font.PLAIN, 14));
        scheduleTable.getTableHeader().setFont(new Font("SansSerif", Font.BOLD, 14));
    }

    private void initLayout() {
        // Основная панель с отступами
        JPanel mainPanel = new JPanel(new BorderLayout(10, 10));
        mainPanel.setBorder(new EmptyBorder(15, 15, 15, 15));

        // Заголовок
        JLabel titleLabel = new JLabel("Текущее учебное расписание");
        titleLabel.setFont(new Font("SansSerif", Font.BOLD, 20));
        titleLabel.setBorder(new EmptyBorder(0, 0, 10, 0));
        mainPanel.add(titleLabel, BorderLayout.NORTH);

        // Таблица в скролл-панели
        JScrollPane scrollPane = new JScrollPane(scheduleTable);
        mainPanel.add(scrollPane, BorderLayout.CENTER);

        // Панель кнопок (Управление)
        JPanel controlPanel = new JPanel(new FlowLayout(FlowLayout.RIGHT));
        
        JButton btnAdd = new JButton("Создать занятие");
        JButton btnDelete = new JButton("Удалить занятие");
        JButton btnRefresh = new JButton("Обновить вид");

        // Стилизация кнопок
        btnAdd.setPreferredSize(new Dimension(150, 40));
        btnDelete.setPreferredSize(new Dimension(150, 40));

        // Логика кнопок
        btnAdd.addActionListener(e -> {
            // Открываем диалог добавления
            LessonDialog dialog = new LessonDialog(this, manager);
            dialog.setVisible(true);
            // После закрытия диалога обновляем таблицу
            refreshTable();
        });

        btnDelete.addActionListener(e -> {
            int selectedRow = scheduleTable.getSelectedRow();
            if (selectedRow != -1) {
                int confirm = JOptionPane.showConfirmDialog(
                    this, 
                    "Вы уверены, что хотите удалить выбранное занятие?",
                    "Подтверждение удаления",
                    JOptionPane.YES_NO_OPTION
                );
                
                if (confirm == JOptionPane.YES_OPTION) {
                    manager.removeLesson(selectedRow);
                    refreshTable();
                }
            } else {
                JOptionPane.showMessageDialog(this, "Пожалуйста, выберите занятие из списка.");
            }
        });

        btnRefresh.addActionListener(e -> refreshTable());

        controlPanel.add(btnRefresh);
        controlPanel.add(btnDelete);
        controlPanel.add(btnAdd);

        mainPanel.add(controlPanel, BorderLayout.SOUTH);

        // Добавляем основную панель в окно
        add(mainPanel);
    }

    /**
     * Метод для принудительного обновления данных в таблице.
     * Вызывается после добавления, удаления или изменения занятий.
     */
    public void refreshTable() {
        tableModel.fireTableDataChanged();
        
        // Статусное сообщение в консоль (для отладки)
        System.out.println("Расписание обновлено. Всего записей: " + manager.getLessons().size());
    }
}
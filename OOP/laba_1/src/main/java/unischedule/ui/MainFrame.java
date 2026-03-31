package unischedule.ui;

import java.awt.BorderLayout;
import java.awt.Dimension;
import java.awt.FlowLayout;
import java.awt.Font;

import javax.swing.*;
import java.awt.*;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;
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
import unischedule.model.*;
import unischedule.ui.components.ScheduleTableModel;


public class MainFrame extends JFrame {
    private JComboBox<String> comboGroupFilter;
    private JComboBox<String> comboDayFilter;
    
    private final ScheduleManager manager;
    private final JTable scheduleTable;
    private final ScheduleTableModel tableModel;
    private JTextField txtStart;
    private JTextField txtEnd;

    public MainFrame(ScheduleManager manager) {
        this.manager = manager;
        
        setTitle("UniSchedule — Система управления расписанием");
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setSize(1000, 600);
        setMinimumSize(new Dimension(800, 400));
        setLocationRelativeTo(null); 

        this.tableModel = new ScheduleTableModel(manager.getLessons());
        this.scheduleTable = new JTable(tableModel);
        
        setupTableAppearance();

        initLayout();
    }

    private void setupTableAppearance() {
        scheduleTable.setRowHeight(30);
        scheduleTable.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        scheduleTable.getTableHeader().setReorderingAllowed(false);
        scheduleTable.setFont(new Font("SansSerif", Font.PLAIN, 14));
        scheduleTable.getTableHeader().setFont(new Font("SansSerif", Font.BOLD, 14));
        
        scheduleTable.setDefaultRenderer(Object.class, new javax.swing.table.DefaultTableCellRenderer() {
            @Override
            public java.awt.Component getTableCellRendererComponent(JTable table, Object value, 
                    boolean isSelected, boolean hasFocus, int row, int column) {
                
                java.awt.Component c = super.getTableCellRendererComponent(table, value, isSelected, hasFocus, row, column);
                
                ScheduleTableModel model = (ScheduleTableModel) table.getModel();
                
                if (model.isHeaderRow(row)) {
                    c.setBackground(new java.awt.Color(230, 240, 255)); 
                    c.setFont(c.getFont().deriveFont(java.awt.Font.BOLD));
                    c.setForeground(new java.awt.Color(0, 51, 153));
                } else {
                    c.setBackground(java.awt.Color.WHITE);
                    c.setForeground(java.awt.Color.BLACK);
                    c.setFont(c.getFont().deriveFont(java.awt.Font.PLAIN));
                    
                    String status = (String) table.getValueAt(row, 1);
                    if ("Отменено".equals(status)) {
                        c.setForeground(java.awt.Color.GRAY);
                    }
                }
        
                if (isSelected) {
                    c.setBackground(table.getSelectionBackground());
                    c.setForeground(table.getSelectionForeground());
                }
                
                return c;
            }
        });
    }

    private void initLayout() {
        JPanel mainPanel = new JPanel(new BorderLayout(10, 10));
        mainPanel.setBorder(new EmptyBorder(15, 15, 15, 15));
        
        JPanel headerContainer = new JPanel();
        headerContainer.setLayout(new BoxLayout(headerContainer, BoxLayout.Y_AXIS));
        
        JLabel titleLabel = new JLabel("Текущее учебное расписание");
            titleLabel.setFont(new Font("SansSerif", Font.BOLD, 20));
            titleLabel.setAlignmentX(Component.LEFT_ALIGNMENT);
            headerContainer.add(titleLabel);
            headerContainer.add(Box.createVerticalStrut(10));
            
        setupFilterPanel(headerContainer);
        
        mainPanel.add(headerContainer, BorderLayout.NORTH);
        
        mainPanel.add(new JScrollPane(scheduleTable), BorderLayout.CENTER);

        JPanel controlPanel = new JPanel(new FlowLayout(FlowLayout.RIGHT));
        
        JButton btnAdd = new JButton("Создать занятие");
        JButton btnDelete = new JButton("Удалить занятие");
        JButton btnRefresh = new JButton("Обновить вид");
        JButton btnEdit = new JButton("Редактировать");
        JButton btnManage = new JButton("Справочники");

        btnAdd.setPreferredSize(new Dimension(150, 40));
        btnDelete.setPreferredSize(new Dimension(150, 40));
        btnRefresh.setPreferredSize(new Dimension(150, 40));
        btnEdit.setPreferredSize(new Dimension(150, 40));
        btnManage.setPreferredSize(new Dimension(150, 40));
        
        btnManage.addActionListener(e -> {
            new ManagementDialog(this, manager).setVisible(true);
        });
        
        btnAdd.addActionListener(e -> {
            LessonDialog dialog = new LessonDialog(this, manager);
            dialog.setVisible(true);
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
                    Lesson lessonToDelete = tableModel.getLessonAt(selectedRow);
                    if (lessonToDelete != null) {
                        // Чтобы удалить правильно, нам нужно найти индекс этого объекта в основном списке менеджера
                        int realIndex = manager.getLessons().indexOf(lessonToDelete);
                        manager.removeLesson(realIndex);
                        refreshTable();
                    } else {
                        JOptionPane.showMessageDialog(this, "Выберите занятие для удаления.");
                    }
                    refreshTable();
                }
            } else {
                JOptionPane.showMessageDialog(this, "Пожалуйста, выберите занятие из списка.");
            }
        });
        
        btnEdit.addActionListener(e -> {
            int selectedRow = scheduleTable.getSelectedRow();
            if (selectedRow != -1) {
                unischedule.model.Lesson lessonToEdit = tableModel.getLessonAt(selectedRow);
                
                if (lessonToEdit != null) {
                    int realIndex = manager.getLessons().indexOf(lessonToEdit);
                    
                    LessonDialog dialog = new LessonDialog(this, manager, lessonToEdit, realIndex);
                    dialog.setVisible(true);
                    
                    refreshTable();
                } else {
                    JOptionPane.showMessageDialog(this, "Выберите занятие, а не заголовок дня.");
                }
            } else {
                JOptionPane.showMessageDialog(this, "Выберите занятие для редактирования.");
            }
        });

        btnRefresh.addActionListener(e -> refreshTable());

        controlPanel.add(btnRefresh);
        controlPanel.add(btnDelete);
        controlPanel.add(btnAdd);
        controlPanel.add(btnEdit);
        controlPanel.add(btnManage);

        mainPanel.add(controlPanel, BorderLayout.SOUTH);

        add(mainPanel);
    }

     public void refreshTable() {
         tableModel.setLessons(manager.getLessons());
         tableModel.fireTableDataChanged();
     }
    
    private void setupFilterPanel(JPanel parent) {
        JPanel filterPanel = new JPanel(new FlowLayout(FlowLayout.LEFT, 15, 10));
        filterPanel.setBorder(BorderFactory.createTitledBorder("Поиск и фильтрация"));
        filterPanel.setAlignmentX(Component.LEFT_ALIGNMENT);
    
        filterPanel.add(new JLabel("Группа:"));
        comboGroupFilter = new JComboBox<>();
        updateGroupFilterItems();
        filterPanel.add(comboGroupFilter);
    
        filterPanel.add(new JLabel("День:"));
        comboDayFilter = new JComboBox<>(new String[]{"Все дни", "Понедельник", "Вторник", "Среда", "Четверг", "Пятница", "Суббота"});
        filterPanel.add(comboDayFilter);
    
        filterPanel.add(new JLabel("С:"));
        txtStart = new JTextField(8);
        filterPanel.add(txtStart);
        filterPanel.add(new JLabel("По:"));
        txtEnd = new JTextField(8);
        filterPanel.add(txtEnd);
    
        JButton btnSearch = new JButton("Найти");
        btnSearch.addActionListener(e -> applyAllFilters());
        filterPanel.add(btnSearch);
        
        JButton btnReset = new JButton("Сбросить");
        btnReset.addActionListener(e -> resetFilters());
        filterPanel.add(btnReset);
    
        parent.add(filterPanel); 
    }
    
    public void updateGroupFilterItems() {
        if (comboGroupFilter == null) return;
        comboGroupFilter.removeAllItems();
        comboGroupFilter.addItem("Все группы");
        for (unischedule.model.StudentGroup g : manager.getGroups()) {
            comboGroupFilter.addItem(g.getName());
        }
    }
    
    private void applyAllFilters() {
        try {
            String selectedGroup = (String) comboGroupFilter.getSelectedItem();
            String selectedDay = (String) comboDayFilter.getSelectedItem();
            
            DateTimeFormatter dtf = DateTimeFormatter.ofPattern("dd.MM.yyyy");
            LocalDate start = txtStart.getText().isEmpty() ? null : LocalDate.parse(txtStart.getText(), dtf);
            LocalDate end = txtEnd.getText().isEmpty() ? null : LocalDate.parse(txtEnd.getText(), dtf);
    
            List<unischedule.model.Lesson> result = manager.getFilteredLessons(selectedGroup, selectedDay, start, end);
            
            tableModel.setLessons(result);
            tableModel.fireTableDataChanged();
        } catch (Exception ex) {
            JOptionPane.showMessageDialog(this, "Ошибка в формате даты. Используйте ДД.ММ.ГГГГ");
        }
    }
    
    private void resetFilters() {
        if (comboGroupFilter != null) comboGroupFilter.setSelectedIndex(0);
        if (comboDayFilter != null) comboDayFilter.setSelectedIndex(0);
    
        if (txtStart != null) txtStart.setText("");
        if (txtEnd != null) txtEnd.setText("");
    
        tableModel.setLessons(manager.getLessons());
        
        tableModel.fireTableDataChanged();
    }
    
    private void applyPeriodFilter() {
        try {
            DateTimeFormatter dtf = DateTimeFormatter.ofPattern("dd.MM.yyyy");
            LocalDate start = LocalDate.parse(txtStart.getText(), dtf);
            LocalDate end = LocalDate.parse(txtEnd.getText(), dtf);
            
            List<Lesson> filtered = manager.getLessonsInPeriod(start, end);
            
            tableModel.setLessons(filtered); 
            tableModel.fireTableDataChanged();
        } catch (Exception ex) {
            JOptionPane.showMessageDialog(this, "Введите даты в формате ДД.ММ.ГГГГ");
        }
    }
}
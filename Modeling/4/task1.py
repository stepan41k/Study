import math
import tkinter as tk
from tkinter import messagebox

import numpy as np


def calculate():
    try:
        λ = float(entry_a.get())
        N = int(entry_n.get())
        
        if λ <= 0:
            messagebox.showerror("Ошибка", "λ должно быть больше нуля")
            return
        
        if N < 20:
            messagebox.showwarning(
                "Внимание", "Для таблицы 4x5 нужно N не менее 20. Установлено N=20."
            )
            N = 20
            entry_n.delete(0, tk.END)
            entry_n.insert(0, "20")

        r = np.random.rand(N)
        x = -np.log(1 - r) / λ

        Mx = 1 / λ
        Dx = 1 / λ**2

        m = np.mean(x)
        g = np.var(x)

        delta1 = math.fabs(Mx - m)
        delta2 = math.fabs(Dx - g)

        # 4. Обновление полей d1 и d2
        entry_d1.config(state="normal")
        entry_d1.delete(0, tk.END)
        entry_d1.insert(0, f"{delta1:.4f}")
        entry_d1.config(state="readonly")

        entry_d2.config(state="normal")
        entry_d2.delete(0, tk.END)
        entry_d2.insert(0, f"{delta2:.4f}")
        entry_d2.config(state="readonly")

        display_values = x[:20]
        table_str = ""
        for i in range(4):  # 4 строки
            row = display_values[i * 5 : (i + 1) * 5]
            row_str = "  ".join([f"{val:8.4f}" for val in row])
            table_str += row_str + "\n\n"

        txt_table.delete(1.0, tk.END)
        txt_table.insert(tk.END, table_str)

    except ValueError:
        messagebox.showerror("Ошибка", "Введите корректные числа в поля a, b, N")


# Создание окна
root = tk.Tk()
root.title("Лабораторная работа")
root.geometry("800x800")

# Блок параметров
input_frame = tk.LabelFrame(root, text=" Параметры ", padx=10, pady=10)
input_frame.pack(padx=20, pady=10, fill="x")

# Сетка для a, b, N
tk.Label(input_frame, text="λ").grid(row=0, column=0, sticky="e")
entry_a = tk.Entry(input_frame, width=10)
entry_a.insert(0, "0")
entry_a.grid(row=0, column=1, padx=5, pady=5)

tk.Label(input_frame, text="N").grid(row=0, column=4, sticky="e")
entry_n = tk.Entry(input_frame, width=10)
entry_n.insert(0, "20")
entry_n.grid(row=0, column=5, padx=5, pady=5)

# Сетка для d1, d2 (только для чтения)
tk.Label(input_frame, text="Δ1").grid(row=1, column=0, sticky="e")
entry_d1 = tk.Entry(
    input_frame, width=15, state="readonly", readonlybackground="#e0e0e0"
)
entry_d1.grid(row=1, column=1, columnspan=2, padx=5, pady=10, sticky="w")

tk.Label(input_frame, text="Δ2").grid(row=1, column=3, sticky="e")
entry_d2 = tk.Entry(
    input_frame, width=15, state="readonly", readonlybackground="#e0e0e0"
)
entry_d2.grid(row=1, column=4, columnspan=2, padx=5, pady=10, sticky="w")

# Кнопка
btn_calc = tk.Button(
    root,
    text="вычислить",
    command=calculate,
    bg="#2196F3",
    fg="black",
    font=("Arial", 9, "bold"),
)
btn_calc.pack(pady=10)

# Поле вывода таблицы
tk.Label(root, text="Таблица значений:").pack()
txt_table = tk.Text(
    root, height=10, width=55, font=("Courier New", 11), padx=10, pady=10
)
txt_table.pack(pady=10)

root.mainloop()

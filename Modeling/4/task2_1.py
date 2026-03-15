import math
import tkinter as tk
from tkinter import messagebox, ttk

import matplotlib.pyplot as plt
import numpy as np
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg


def draw_hist(frame, data, title):
    """Отрисовка гистограммы"""
    for widget in frame.winfo_children():
        widget.destroy()
    fig, ax = plt.subplots(figsize=(5, 2.8), dpi=80)

    n = len(data)
    xmin, xmax = min(data), max(data)
    m = int(1 + 3.322 * math.log10(n))
    h = (xmax - xmin) / m

    ni_counts = []
    for i in range(m):
        low = xmin + i * h
        high = xmin + (i + 1) * h

        if i == m - 1:
            count = len([x for x in data if low <= x <= high])
        else:
            count = len([x for x in data if low <= x < high])
        ni_counts.append(count)

    print(ni_counts)

    ax.hist(data, bins=m, color="skyblue", edgecolor="black", alpha=0.7)
    ax.set_title(title)
    canvas = FigureCanvasTkAgg(fig, master=frame)
    canvas.draw()
    canvas.get_tk_widget().pack(fill="both", expand=True)


def calc_normal():
    try:
        a = float(ent_norm_a.get())
        sigma = float(ent_norm_sigma.get())
        N = int(ent_norm_n.get())

        if sigma <= 0:
            messagebox.showerror("Ошибка", "Параметр 'σ' должен быть больше 0")
            return
        if N < 20:
            N = 20
            ent_norm_n.delete(0, tk.END)
            ent_norm_n.insert(0, "20")

        Mx = a
        Dx = sigma * sigma

        x = []
        for _ in range(N):
            xi = np.random.rand(12).sum() - 6
            x.append(a + xi * sigma)

        m = np.sum(x) / N
        squared_deviations = (x - m) ** 2
        g = np.sum(squared_deviations) / N

        update_ui(ent_norm_d1, ent_norm_d2, txt_norm_table, Mx, Dx, m, g, x)
        draw_hist(f1_hist, x, "Гистограмма (Нормальное)")
    except ValueError:
        messagebox.showerror("Ошибка", "Введите корректные числа")


def calc_uniform():
    try:
        a = float(ent_uni_a.get())
        b = float(ent_uni_b.get())
        N = int(ent_uni_n.get())

        if a >= b:
            messagebox.showerror("Ошибка", "Параметр 'a' должен быть меньше 'b'")
            return
        if N < 20:
            N = 20
            ent_uni_n.delete(0, tk.END)
            ent_uni_n.insert(0, "20")

        Mx = (a + b) / 2
        Dx = ((b - a) ** 2) / 12

        r = np.random.rand(N)
        x = a + r * (b - a)

        Mx = (a + b) / 2
        Dx = ((b - a) ** 2) / 12

        m = np.sum(x) / N
        squared_deviations = (x - m) ** 2
        g = np.sum(squared_deviations) / N

        update_ui(ent_uni_d1, ent_uni_d2, txt_uni_table, Mx, Dx, m, g, x)
        draw_hist(f2_hist, x, "Гистограмма (Равномерное)")
    except ValueError:
        messagebox.showerror("Ошибка", "Введите корректные числа")


def update_ui(ed1, ed2, txt, Mx, Dx, m, g, x):
    d1, d2 = math.fabs(Mx - m), math.fabs(Dx - g)

    for e, val in zip([ed1, ed2], [d1, d2]):
        e.config(state="normal")
        e.delete(0, tk.END)
        e.insert(0, f"{val:.4f}")
        e.config(state="readonly")

    display_values = x[:20]
    table_str = ""
    for i in range(4):
        row = display_values[i * 5 : (i + 1) * 5]
        row_str = "  ".join([f"{val:8.4f}" for val in row])
        table_str += row_str + "\n\n"

    txt.delete(1.0, tk.END)
    txt.insert(tk.END, table_str)


# --- ИНТЕРФЕЙС ---
root = tk.Tk()
root.title(
    "Лабораторная работа: 4 Равномерное и нормальное распределения + гистограммы"
)
root.geometry("600x650")

notebook = ttk.Notebook(root)
notebook.pack(padx=10, pady=10, expand=True, fill="both")

# Вкладка 1: НОРМАЛЬНОЕ
tab1 = ttk.Frame(notebook)
notebook.add(tab1, text=" Нормальное ")
f1 = tk.LabelFrame(tab1, text=" Параметры (a, σ) ", padx=10, pady=10)
f1.pack(padx=20, pady=10, fill="x")
tk.Label(f1, text="a").grid(row=0, column=0)
ent_norm_a = tk.Entry(f1, width=10)
ent_norm_a.insert(0, "0")
ent_norm_a.grid(row=0, column=1)
tk.Label(f1, text="σ").grid(row=0, column=2)
ent_norm_sigma = tk.Entry(f1, width=10)
ent_norm_sigma.insert(0, "1")
ent_norm_sigma.grid(row=0, column=3)
tk.Label(f1, text="N").grid(row=0, column=4)
ent_norm_n = tk.Entry(f1, width=10)
ent_norm_n.insert(0, "20")
ent_norm_n.grid(row=0, column=5)
tk.Label(f1, text="Δ1").grid(row=1, column=0)
ent_norm_d1 = tk.Entry(f1, width=15, state="readonly")
ent_norm_d1.grid(row=1, column=1, columnspan=2)
tk.Label(f1, text="Δ2").grid(row=1, column=3)
ent_norm_d2 = tk.Entry(f1, width=15, state="readonly")
ent_norm_d2.grid(row=1, column=4, columnspan=2)
tk.Button(
    tab1, text="вычислить", command=calc_normal, bg="#2196F3", font=("Arial", 9, "bold")
).pack(pady=10)
txt_norm_table = tk.Text(tab1, height=10, width=55, font=("Courier New", 11))
txt_norm_table.pack()

f1_hist = tk.Frame(tab1)
f1_hist.pack(fill="both", expand=True)

# Вкладка 2: РАВНОМЕРНОЕ
tab2 = ttk.Frame(notebook)
notebook.add(tab2, text=" Равномерное ")
f2 = tk.LabelFrame(tab2, text=" Параметры (a, b) ", padx=10, pady=10)
f2.pack(padx=20, pady=10, fill="x")
tk.Label(f2, text="a").grid(row=0, column=0)
ent_uni_a = tk.Entry(f2, width=10)
ent_uni_a.insert(0, "0")
ent_uni_a.grid(row=0, column=1)
tk.Label(f2, text="b").grid(row=0, column=2)
ent_uni_b = tk.Entry(f2, width=10)
ent_uni_b.insert(0, "1")
ent_uni_b.grid(row=0, column=3)
tk.Label(f2, text="N").grid(row=0, column=4)
ent_uni_n = tk.Entry(f2, width=10)
ent_uni_n.insert(0, "20")
ent_uni_n.grid(row=0, column=5)
tk.Label(f2, text="Δ1").grid(row=1, column=0)
ent_uni_d1 = tk.Entry(f2, width=15, state="readonly")
ent_uni_d1.grid(row=1, column=1, columnspan=2)
tk.Label(f2, text="Δ2").grid(row=1, column=3)
ent_uni_d2 = tk.Entry(f2, width=15, state="readonly")
ent_uni_d2.grid(row=1, column=4, columnspan=2)
tk.Button(
    tab2,
    text="вычислить",
    command=calc_uniform,
    bg="#2196F3",
    font=("Arial", 9, "bold"),
).pack(pady=10)
txt_uni_table = tk.Text(tab2, height=10, width=55, font=("Courier New", 11))
txt_uni_table.pack()

f2_hist = tk.Frame(tab2)
f2_hist.pack(fill="both", expand=True)

root.mainloop()

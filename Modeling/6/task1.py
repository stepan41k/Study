import math
import tkinter as tk
from tkinter import messagebox, ttk

import matplotlib.pyplot as plt
import numpy as np
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg

# --- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ---


def draw_hist(frame, data, bins, title):
    """Отрисовка гистограммы"""
    for widget in frame.winfo_children():
        widget.destroy()
    fig, ax = plt.subplots(figsize=(5, 2.8), dpi=80)
    ax.hist(data, bins=bins, color="skyblue", edgecolor="black", alpha=0.7)
    ax.set_title(title)
    canvas = FigureCanvasTkAgg(fig, master=frame)
    canvas.draw()
    canvas.get_tk_widget().pack(fill="both", expand=True)


def update_ui(txt, ed1, ed2, Mx, Dx, sample_m, sample_v, x, k_bins):
    """Вывод таблицы 20 значений и частот ni"""
    # 1. Погрешности
    d1, d2 = math.fabs(Mx - sample_m), math.fabs(Dx - sample_v)
    for e, val in zip([ed1, ed2], [d1, d2]):
        e.config(state="normal")
        e.delete(0, tk.END)
        e.insert(0, f"{val:.4f}")
        e.config(state="readonly")

    # 2. Формирование текста (20 значений + ni)
    output = "ПЕРВЫЕ 20 ЗНАЧЕНИЙ:\n"
    display_values = x[:20]
    for i in range(4):
        row = display_values[i * 5 : (i + 1) * 5]
        output += "  ".join([f"{val:8.4f}" for val in row]) + "\n"

    output += "\nРАСПРЕДЕЛЕНИЕ ЧАСТОТ (ni):\n"
    output += f"{'Интервал':^20} | {'ni':^6}\n"
    output += "-" * 30 + "\n"

    # Расчет ni
    counts, bins = np.histogram(x, bins=k_bins)
    for i in range(len(counts)):
        output += f"[{bins[i]:6.2f}, {bins[i + 1]:6.2f}] | {counts[i]:^6}\n"

    txt.delete(1.0, tk.END)
    txt.insert(tk.END, output)


# --- ФУНКЦИИ РАСЧЕТА ---


def calc_normal():
    try:
        a = float(ent_norm_a.get())
        sigma = float(ent_norm_sigma.get())
        N = int(ent_norm_n.get())
        m_bins = int(ent_norm_m.get())

        if sigma <= 0 or N < 20:
            raise ValueError

        # Генерация (ЦПТ)
        x = [a + (np.random.rand(12).sum() - 6) * sigma for _ in range(N)]

        update_ui(
            txt_norm,
            ent_norm_d1,
            ent_norm_d2,
            a,
            sigma**2,
            np.mean(x),
            np.var(x),
            x,
            m_bins,
        )
        draw_hist(f1_hist, x, m_bins, "Гистограмма (Нормальное)")
    except:
        messagebox.showerror("Ошибка", "Проверьте ввод: σ > 0, N >= 20, m > 0")


def calc_uniform():
    try:
        a = float(ent_uni_a.get())
        b = float(ent_uni_b.get())
        N = int(ent_uni_n.get())
        m_bins = int(ent_uni_m.get())

        if a >= b or N < 20:
            raise ValueError

        x = a + np.random.rand(N) * (b - a)
        Mx, Dx = (a + b) / 2, ((b - a) ** 2) / 12

        update_ui(
            txt_uni, ent_uni_d1, ent_uni_d2, Mx, Dx, np.mean(x), np.var(x), x, m_bins
        )
        draw_hist(f3_hist, x, m_bins, "Гистограмма (Равномерное)")
    except:
        messagebox.showerror("Ошибка", "Проверьте ввод: a < b, N >= 20, m > 0")


# --- ИНТЕРФЕЙС ---
root = tk.Tk()
root.title("Лабораторная работа: Значения, ni и Гистограммы")
root.geometry("620x900")

nb = ttk.Notebook(root)
nb.pack(expand=True, fill="both")

# ВКЛАДКА 1: НОРМАЛЬНОЕ
tab1 = ttk.Frame(nb)
nb.add(tab1, text=" Нормальное ")
f1 = tk.LabelFrame(tab1, text=" Параметры ", padx=10, pady=10)
f1.pack(fill="x", padx=15)

tk.Label(f1, text="a").grid(row=0, column=0)
ent_norm_a = tk.Entry(f1, width=7)
ent_norm_a.insert(0, "0")
ent_norm_a.grid(row=0, column=1)
tk.Label(f1, text="σ").grid(row=0, column=2)
ent_norm_sigma = tk.Entry(f1, width=7)
ent_norm_sigma.insert(0, "1")
ent_norm_sigma.grid(row=0, column=3)
tk.Label(f1, text="N").grid(row=0, column=4)
ent_norm_n = tk.Entry(f1, width=7)
ent_norm_n.insert(0, "100")
ent_norm_n.grid(row=0, column=5)
tk.Label(f1, text="m").grid(row=0, column=6)
ent_norm_m = tk.Entry(f1, width=5)
ent_norm_m.insert(0, "10")
ent_norm_m.grid(row=0, column=7)

tk.Label(f1, text="Δ1").grid(row=1, column=0)
ent_norm_d1 = tk.Entry(f1, width=12, state="readonly")
ent_norm_d1.grid(row=1, column=1, columnspan=2)
tk.Label(f1, text="Δ2").grid(row=1, column=3)
ent_norm_d2 = tk.Entry(f1, width=12, state="readonly")
ent_norm_d2.grid(row=1, column=4, columnspan=2)

tk.Button(
    tab1,
    text="ВЫЧИСЛИТЬ",
    command=calc_normal,
    bg="#2196F3",
    fg="white",
    font=("Arial", 9, "bold"),
).pack(pady=5)
txt_norm = tk.Text(tab1, height=12, width=65, font=("Courier New", 10))
txt_norm.pack()
f1_hist = tk.Frame(tab1)
f1_hist.pack(fill="both", expand=True)

# ВКЛАДКА 2: РАВНОМЕРНОЕ
tab2 = ttk.Frame(nb)
nb.add(tab2, text=" Равномерное ")
f2 = tk.LabelFrame(tab2, text=" Параметры ", padx=10, pady=10)
f2.pack(fill="x", padx=15)

tk.Label(f2, text="a").grid(row=0, column=0)
ent_uni_a = tk.Entry(f2, width=7)
ent_uni_a.insert(0, "0")
ent_uni_a.grid(row=0, column=1)
tk.Label(f2, text="b").grid(row=0, column=2)
ent_uni_b = tk.Entry(f2, width=7)
ent_uni_b.insert(0, "1")
ent_uni_b.grid(row=0, column=3)
tk.Label(f2, text="N").grid(row=0, column=4)
ent_uni_n = tk.Entry(f2, width=7)
ent_uni_n.insert(0, "100")
ent_uni_n.grid(row=0, column=5)
tk.Label(f2, text="m").grid(row=0, column=6)
ent_uni_m = tk.Entry(f2, width=5)
ent_uni_m.insert(0, "10")
ent_uni_m.grid(row=0, column=7)

tk.Label(f2, text="Δ1").grid(row=1, column=0)
ent_uni_d1 = tk.Entry(f2, width=12, state="readonly")
ent_uni_d1.grid(row=1, column=1, columnspan=2)
tk.Label(f2, text="Δ2").grid(row=1, column=3)
ent_uni_d2 = tk.Entry(f2, width=12, state="readonly")
ent_uni_d2.grid(row=1, column=4, columnspan=2)

tk.Button(
    tab2,
    text="ВЫЧИСЛИТЬ",
    command=calc_uniform,
    bg="#4CAF50",
    fg="white",
    font=("Arial", 9, "bold"),
).pack(pady=5)
txt_uni = tk.Text(tab2, height=12, width=65, font=("Courier New", 10))
txt_uni.pack()
f3_hist = tk.Frame(tab2)
f3_hist.pack(fill="both", expand=True)

root.mainloop()

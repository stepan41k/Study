import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import math

n = 10
#N = [10, 100, 1000, 10000, 100000]
try:
    print("Введите значения N через пробел:")
    user_input = input()
    N = [int(x) for x in user_input.split()]
    
    if not N:
        print("Ввод пуст, используются значения по умолчанию.")
        N = [100, 200, 300, 400, 500]
except ValueError:
    print("Ошибка ввода! Используются значения по умолчанию.")
    N = [100, 200, 300, 400, 500]

Mx = (n + 1) / (n + 2)
Dx = (n + 1) / ((n + 3) * (n + 2) ** 2)

print(f"Теоретическое Mx = {Mx:.6f}")
print(f"Теоретическое Dx = {Dx:.6f}")


# Функции
def f(x):
    return np.where(x < 0, 0, np.where(x > 1, 0, (n + 1) * (x ** n)))


def F(x):
    return np.where(x < 0, 0, np.where(x > 1, 1, x ** (n + 1)))


def simulate(N):
    r = np.random.rand(N)
    x = r ** (1 / (n + 1))

    m = np.sum(x) / N
    squared_deviations = (x - m) ** 2
    g = np.sum(squared_deviations) / N

    delta1 = math.fabs(Mx - m)
    delta2 = math.fabs(Dx - g)

    return m, g, delta1, delta2


rows = []
for N_curr in N:
    m, g, d1, d2 = simulate(N_curr)
    rows.append([N_curr, Mx, m, d1, Dx, g, d2])

df = pd.DataFrame(rows, columns=["N", "Mx", "m", "|Mx-m|", "Dx", "g", "|Dx-g|"])
print("\n", df.round(6))

x_vals = np.linspace(-0.2, 1.2, 400)

fig, ax = plt.subplots(figsize=(10, 3))
ax.axis("off")
table = ax.table(
    cellText=df.round(6).values,
    colLabels=df.columns,
    loc="center",
    cellLoc="center"
)
table.auto_set_font_size(False)
table.set_fontsize(10)
table.scale(1.2, 1.5)
ax.set_title("Результаты моделирования", fontweight="bold")
plt.show()
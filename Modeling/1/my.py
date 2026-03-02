import math

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

N = [120, 240, 360, 480, 600]

Mx = math.pi/4 - math.log(2)/2
Dx = 0.041

print(f"Теоретическое Mx = {Mx:.6f}")
print(f"Теоретическое Dx = {Dx:.6f}")


# Функции
def f(x):
    return np.where(x < 0, 0, np.where(x > math.pi/4, 0, (1 / math.cos(x) ** 2)))


def F(x):
    return np.where(x < 1, 0, np.where(x > 2, 1, math.tan(x)))


def simulate(N):
    r = np.random.rand(N)
    # x = math.atan(r)
    x = np.arctan(r)

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

x_vals = np.linspace(0.8, 2.2, 400)

fig, ax = plt.subplots(figsize=(10, 3))
ax.axis("off")
table = ax.table(
    cellText=df.round(6).values, colLabels=df.columns, loc="center", cellLoc="center"
)
table.auto_set_font_size(False)
table.set_fontsize(10)
table.scale(1.2, 1.5)
ax.set_title("Результаты моделирования", fontweight="bold")
plt.show()

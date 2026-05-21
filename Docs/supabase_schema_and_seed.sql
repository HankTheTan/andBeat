-- ============================================================
-- andBeat — Supabase 初始化脚本
-- 执行方式：粘贴到 Supabase SQL Editor 运行
-- https://supabase.com/dashboard/project/ycdwhokltspzznwcdccg/sql/new
-- ============================================================

-- ── 1. users 表 ─────────────────────────────────────────────
create table if not exists public.users (
    id           uuid primary key default gen_random_uuid(),
    user_name    text        not null,
    email        text        unique,
    created_at   timestamptz not null default now(),
    updated_at   timestamptz not null default now()
);

-- ── 2. cycle_profiles 表 ────────────────────────────────────
create table if not exists public.cycle_profiles (
    id                  uuid primary key default gen_random_uuid(),
    user_id             uuid        not null references public.users(id) on delete cascade,
    last_period_start   date        not null,
    cycle_length        int         not null default 28,
    period_length       int         not null default 5,
    created_at          timestamptz not null default now(),
    updated_at          timestamptz not null default now()
);

-- ── 3. daily_metrics 表 ─────────────────────────────────────
create table if not exists public.daily_metrics (
    id                  uuid primary key default gen_random_uuid(),
    user_id             uuid        not null references public.users(id) on delete cascade,
    record_date         date        not null,
    recorded_at         timestamptz not null,      -- 实际记录时间 (早 8 点)
    heart_rate          numeric(5,2),              -- bpm
    body_temperature    numeric(4,2),              -- °C
    hrv                 numeric(5,2),              -- ms
    respiratory_rate    numeric(4,2),              -- 次/min
    notes               text,
    created_at          timestamptz not null default now(),
    unique (user_id, record_date)
);

-- ── 4. 自动更新 updated_at 的触发器 ─────────────────────────
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

create or replace trigger trg_users_updated_at
    before update on public.users
    for each row execute function public.set_updated_at();

create or replace trigger trg_cycle_profiles_updated_at
    before update on public.cycle_profiles
    for each row execute function public.set_updated_at();

-- ── 5. Row Level Security（先开启，策略后续按需添加）────────
alter table public.users          enable row level security;
alter table public.cycle_profiles enable row level security;
alter table public.daily_metrics  enable row level security;

-- 临时允许 service_role 全量读写（anon 无法访问，生产前替换为具体策略）
create policy "service role full access" on public.users
    for all using (true) with check (true);
create policy "service role full access" on public.cycle_profiles
    for all using (true) with check (true);
create policy "service role full access" on public.daily_metrics
    for all using (true) with check (true);

-- ============================================================
-- 6. 种子数据 — 用户「林夏」
--    周期背景：28天周期，上次经期 2026-05-08，今日为第 14 天（排卵日）
--    健康数据：过去 8 天早 8 点同步，BBT 升高趋势，HRV 随排卵轻微下降
-- ============================================================

-- 6-1. 插入用户
insert into public.users (id, user_name, email)
values (
    '11111111-1111-1111-1111-111111111111',
    '林夏',
    'linxia@andbeat.app'
);

-- 6-2. 插入周期档案
insert into public.cycle_profiles (user_id, last_period_start, cycle_length, period_length)
values (
    '11111111-1111-1111-1111-111111111111',
    '2026-05-08',   -- 13 天前，当前周期第 14 天
    28,
    5
);

-- 6-3. 插入 8 天每日健康数据
insert into public.daily_metrics
    (user_id, record_date, recorded_at, heart_rate, body_temperature, hrv, respiratory_rate)
values
-- 周期 D7  卵泡期中段，能量恢复
('11111111-1111-1111-1111-111111111111', '2026-05-14', '2026-05-14 08:05:00+00', 67.00, 36.25, 58.00, 15.0),
-- 周期 D8  状态稳定上升
('11111111-1111-1111-1111-111111111111', '2026-05-15', '2026-05-15 08:08:00+00', 69.00, 36.30, 55.00, 15.0),
-- 周期 D9  雌激素继续升高
('11111111-1111-1111-1111-111111111111', '2026-05-16', '2026-05-16 08:03:00+00', 71.00, 36.35, 53.00, 16.0),
-- 周期 D10 接近排卵前期
('11111111-1111-1111-1111-111111111111', '2026-05-17', '2026-05-17 08:11:00+00', 72.00, 36.40, 50.00, 16.0),
-- 周期 D11 LH 峰值前，轻微紧张
('11111111-1111-1111-1111-111111111111', '2026-05-18', '2026-05-18 08:07:00+00', 74.00, 36.45, 47.00, 16.0),
-- 周期 D12 LH surge 开始，体温预升
('11111111-1111-1111-1111-111111111111', '2026-05-19', '2026-05-19 08:02:00+00', 76.00, 36.55, 44.00, 17.0),
-- 周期 D13 排卵前夜，BBT 显著升高
('11111111-1111-1111-1111-111111111111', '2026-05-20', '2026-05-20 08:09:00+00', 78.00, 36.72, 41.00, 17.0),
-- 周期 D14 排卵日，心率稍回落，体温维持高位（今日）
('11111111-1111-1111-1111-111111111111', '2026-05-21', '2026-05-21 08:06:00+00', 72.00, 36.68, 45.00, 16.0);

-- ============================================================
-- 验证查询
-- ============================================================
select
    u.user_name,
    cp.last_period_start,
    cp.cycle_length,
    cp.period_length,
    (current_date - cp.last_period_start) + 1 as current_cycle_day
from public.users u
join public.cycle_profiles cp on cp.user_id = u.id;

select
    record_date,
    heart_rate    as "心率(bpm)",
    body_temperature as "体温(°C)",
    hrv           as "HRV(ms)",
    respiratory_rate as "呼吸(/min)"
from public.daily_metrics
where user_id = '11111111-1111-1111-1111-111111111111'
order by record_date;

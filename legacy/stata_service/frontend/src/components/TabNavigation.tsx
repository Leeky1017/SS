import { Upload, Search } from "lucide-react";

export type TabType = 'submit' | 'query';

interface Tab {
    id: TabType;
    label: string;
    icon: React.ReactNode;
}

interface TabNavigationProps {
    activeTab: TabType;
    onTabChange: (tab: TabType) => void;
}

const tabs: Tab[] = [
    {
        id: 'submit',
        label: '提交需求',
        icon: <Upload className="w-4 h-4" />,
    },
    {
        id: 'query',
        label: '结果查询',
        icon: <Search className="w-4 h-4" />,
    },
];

export function TabNavigation({ activeTab, onTabChange }: TabNavigationProps) {
    return (
        <div className="container mx-auto px-6 pt-6">
            <div className="flex justify-center">
                <div className="inline-flex items-center p-1 bg-slate-100/70 backdrop-blur-sm rounded-xl border border-slate-200/50 shadow-sm">
                    {tabs.map((tab) => {
                        const isActive = activeTab === tab.id;
                        return (
                            <button
                                key={tab.id}
                                onClick={() => onTabChange(tab.id)}
                                className={`
                                    flex items-center gap-2 px-6 py-2.5 rounded-lg font-medium text-sm transition-all duration-200
                                    ${isActive
                                        ? 'bg-white text-slate-900 shadow-md'
                                        : 'text-slate-500 hover:text-slate-700'
                                    }
                                `}
                            >
                                {tab.icon}
                                <span>{tab.label}</span>
                            </button>
                        );
                    })}
                </div>
            </div>
        </div>
    );
}

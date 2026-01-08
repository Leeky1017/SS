import { useState } from "react";
import { HelpCircle, CheckCircle2 } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "./ui/card";
import { Button } from "./ui/button";
import type { ClarificationQuestion } from "@/api/stataService";

interface ClarificationQuestionsProps {
    questions: ClarificationQuestion[];
    answers: Record<string, string[]>;
    onAnswerChange: (questionId: string, optionIds: string[]) => void;
}

export function ClarificationQuestions({
    questions,
    answers,
    onAnswerChange,
}: ClarificationQuestionsProps) {
    const [expandedQuestion, setExpandedQuestion] = useState<string | null>(
        questions[0]?.question_id || null
    );

    if (questions.length === 0) {
        return (
            <Card className="border-green-200 bg-green-50">
                <CardContent className="py-6">
                    <div className="flex items-center gap-3 text-green-700">
                        <CheckCircle2 className="h-6 w-6" />
                        <div>
                            <div className="font-medium">需求理解完整</div>
                            <div className="text-sm text-green-600">无需额外确认，可直接执行</div>
                        </div>
                    </div>
                </CardContent>
            </Card>
        );
    }

    const handleOptionClick = (
        question: ClarificationQuestion,
        optionId: string
    ) => {
        if (question.question_type === "single_choice") {
            onAnswerChange(question.question_id, [optionId]);
        } else {
            // multi_choice
            const currentAnswers = answers[question.question_id] || [];
            if (currentAnswers.includes(optionId)) {
                onAnswerChange(
                    question.question_id,
                    currentAnswers.filter((id) => id !== optionId)
                );
            } else {
                onAnswerChange(question.question_id, [...currentAnswers, optionId]);
            }
        }
    };

    const isOptionSelected = (questionId: string, optionId: string) => {
        return (answers[questionId] || []).includes(optionId);
    };

    const getAnsweredCount = () => {
        return questions.filter((q) => (answers[q.question_id] || []).length > 0).length;
    };

    return (
        <Card className="border-amber-200 bg-amber-50/50">
            <CardHeader className="pb-3">
                <CardTitle className="text-lg flex items-center justify-between">
                    <div className="flex items-center gap-2">
                        <HelpCircle className="h-5 w-5 text-amber-600" />
                        系统待确认事项
                    </div>
                    <span className="text-sm font-normal text-muted-foreground">
                        已回答 {getAnsweredCount()}/{questions.length}
                    </span>
                </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
                {questions.map((question, idx) => (
                    <div
                        key={question.question_id}
                        className={`rounded-lg border transition-all ${expandedQuestion === question.question_id
                            ? "border-amber-400 bg-amber-50/80"
                            : "border-border bg-card"
                            }`}
                    >
                        <button
                            type="button"
                            className="w-full p-4 text-left flex items-start gap-3"
                            onClick={() =>
                                setExpandedQuestion(
                                    expandedQuestion === question.question_id
                                        ? null
                                        : question.question_id
                                )
                            }
                        >
                            <span
                                className={`flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold shadow-sm border-2 ${(answers[question.question_id] || []).length > 0
                                    ? "bg-green-100 text-green-700 border-green-300"
                                    : "bg-amber-100 text-amber-700 border-amber-300"
                                    }`}
                            >
                                {(answers[question.question_id] || []).length > 0 ? (
                                    <CheckCircle2 className="h-5 w-5" />
                                ) : (
                                    idx + 1
                                )}
                            </span>
                            <div className="flex-1">
                                <div className="font-medium text-sm">{question.question_text}</div>
                                {(answers[question.question_id] || []).length > 0 && (
                                    <div className="text-xs text-green-600 mt-1">
                                        已选择{" "}
                                        {
                                            question.options.filter((opt) =>
                                                (answers[question.question_id] || []).includes(opt.option_id)
                                            )[0]?.label
                                        }
                                    </div>
                                )}
                            </div>
                        </button>

                        {expandedQuestion === question.question_id && (
                            <div className="px-4 pb-4 pt-0">
                                <div className="grid gap-2">
                                    {question.options.map((option) => (
                                        <Button
                                            key={option.option_id}
                                            type="button"
                                            variant={
                                                isOptionSelected(question.question_id, option.option_id)
                                                    ? "default"
                                                    : "outline"
                                            }
                                            className={`justify-start h-auto py-3 px-4 text-left whitespace-normal ${isOptionSelected(question.question_id, option.option_id)
                                                ? ""
                                                : "hover:bg-accent/50"
                                                }`}
                                            onClick={() =>
                                                handleOptionClick(question, option.option_id)
                                            }
                                        >
                                            <span
                                                className={`w-4 h-4 rounded-full border-2 mr-3 flex-shrink-0 flex items-center justify-center ${isOptionSelected(question.question_id, option.option_id)
                                                    ? "border-primary-foreground bg-primary-foreground"
                                                    : "border-current"
                                                    }`}
                                            >
                                                {isOptionSelected(
                                                    question.question_id,
                                                    option.option_id
                                                ) && (
                                                        <span className="w-2 h-2 rounded-full bg-primary" />
                                                    )}
                                            </span>
                                            <span className="text-sm">{option.label}</span>
                                        </Button>
                                    ))}
                                </div>
                            </div>
                        )}
                    </div>
                ))}
            </CardContent>
        </Card>
    );
}

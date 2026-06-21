<?php

namespace App\Domains\Vault\ManageVault\Api\Controllers;

use App\Http\Controllers\ApiController;
use App\Models\ContactReminder;
use App\Models\ContactTask;
use App\Models\Post;
use Illuminate\Http\Request;

/**
 * @group Vault management
 *
 * @subgroup Dashboard
 *
 * Cross-contact rollups for the mobile vault dashboard (due tasks, upcoming
 * reminders, recent journal posts).
 */
class VaultDashboardApiController extends ApiController
{
    public function __construct()
    {
        $this->middleware('abilities:read');

        parent::__construct();
    }

    private function vault(Request $request, string $vaultId)
    {
        return $request->user()->account->vaults()->findOrFail($vaultId);
    }

    private function contactStub($contact): array
    {
        return [
            'id' => $contact->id,
            'name' => $contact->name,
            'avatar' => $contact->avatar,
        ];
    }

    public function tasks(Request $request, string $vaultId)
    {
        $vault = $this->vault($request, $vaultId);

        $tasks = ContactTask::whereHas('contact', fn ($q) => $q->where('vault_id', $vault->id))
            ->where('completed', false)
            ->with('contact.file')
            ->orderByRaw('due_at IS NULL, due_at ASC')
            ->limit(300)
            ->get();

        return response()->json([
            'data' => $tasks->map(fn ($t) => [
                'id' => $t->id,
                'label' => $t->label,
                'description' => $t->description,
                'completed' => $t->completed,
                'due_at' => optional($t->due_at)->format('Y-m-d'),
                'contact' => $this->contactStub($t->contact),
            ]),
        ]);
    }

    public function reminders(Request $request, string $vaultId)
    {
        $vault = $this->vault($request, $vaultId);

        $reminders = ContactReminder::whereHas('contact', fn ($q) => $q->where('vault_id', $vault->id))
            ->with('contact.file')
            ->orderByRaw('month ASC, day ASC')
            ->limit(300)
            ->get();

        return response()->json([
            'data' => $reminders->map(fn ($r) => [
                'id' => $r->id,
                'label' => $r->label,
                'day' => $r->day,
                'month' => $r->month,
                'year' => $r->year,
                'type' => $r->type,
                'contact' => $this->contactStub($r->contact),
            ]),
        ]);
    }

    public function posts(Request $request, string $vaultId)
    {
        $vault = $this->vault($request, $vaultId);

        $posts = Post::whereHas('journal', fn ($q) => $q->where('vault_id', $vault->id))
            ->with('journal')
            ->orderByDesc('written_at')
            ->limit(100)
            ->get();

        return response()->json([
            'data' => $posts->map(fn ($p) => [
                'id' => $p->id,
                'title' => $p->title,
                'written_at' => optional($p->written_at)->format('Y-m-d'),
                'journal' => optional($p->journal)->name,
            ]),
        ]);
    }
}
